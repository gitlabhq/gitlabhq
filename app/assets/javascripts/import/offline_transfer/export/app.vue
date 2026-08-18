<script>
import { DEFAULT_PER_PAGE } from '~/api';
import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';
import {
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
  HTTP_STATUS_TOO_MANY_REQUESTS,
} from '~/lib/utils/http_status';
import { s__ } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import SelectGroupsTab from '~/import/offline_transfer/export/select_groups_tab.vue';
import ExportConfigTab from '~/import/offline_transfer/export/export_config_tab.vue';
import { OFFLINE_EXPORT_TAB_HEADINGS } from '../constants';
import ReviewExportTab from './review_export_tab.vue';
import { isStorageConfigValid } from './storage_config_validation';

export default {
  name: 'OfflineTransferExportApp',
  components: {
    FormStepper,
    SelectGroupsTab,
    ExportConfigTab,
    ReviewExportTab,
  },
  data() {
    return {
      offlineTransferSourceOwnedGroups: null,
      selectedGroups: [],
      search: '',
      startCursor: null,
      endCursor: null,

      showFetchError: false,
      showSelectError: false,
      showStorageConfigError: false,
      hasSubmitSucceeded: false,
      submissionError: '',
      isSubmitting: false,
      isRetryBlocked: false,
      storageConfig: {
        accessKeyId: '',
        secretAccessKey: '',
        region: '',
        bucketName: '',
        pathStyle: false,
      },
    };
  },

  apollo: {
    offlineTransferSourceOwnedGroups: {
      query: offlineTransferSourceOwnedGroupsQuery,
      // leverages `loading` on both search + pagination, not just initial query
      notifyOnNetworkStatusChange: true,
      update(data) {
        return data.groups;
      },
      variables() {
        return {
          search: this.search,
          ...this.pagination,
        };
      },
      error(error) {
        this.showFetchError = true;
        captureException(error);
      },
    },
  },

  computed: {
    currentPageGroups() {
      return this.offlineTransferSourceOwnedGroups?.nodes ?? [];
    },
    pageInfo() {
      return this.offlineTransferSourceOwnedGroups?.pageInfo;
    },
    pagination() {
      if (!this.startCursor && !this.endCursor) {
        return { first: DEFAULT_PER_PAGE, after: null, last: null, before: null };
      }

      return {
        first: this.endCursor && DEFAULT_PER_PAGE,
        after: this.endCursor,
        last: this.startCursor && DEFAULT_PER_PAGE,
        before: this.startCursor,
      };
    },
    selectedGroupIds() {
      return this.selectedGroups.map((group) => group.id);
    },
    isLoading() {
      return this.$apollo.queries.offlineTransferSourceOwnedGroups.loading;
    },
    isInitialLoading() {
      return this.isLoading && !this.offlineTransferSourceOwnedGroups;
    },
    selectedGroupsCount() {
      return this.selectedGroups.length;
    },
    isEmptyGroupsList() {
      return !this.isLoading && !this.search && !this.currentPageGroups.length;
    },
    canStart() {
      if (this.selectedGroupsCount > 0) return true;
      // Block starting the wizard when there is nothing to select
      if (this.showFetchError) return false;
      return !this.isEmptyGroupsList;
    },
    exportPayload() {
      return {
        bucket: this.storageConfig.bucketName.trim(),
        aws_s3_configuration: {
          aws_access_key_id: this.storageConfig.accessKeyId.trim(),
          aws_secret_access_key: this.storageConfig.secretAccessKey.trim(),
          region: this.storageConfig.region.trim(),
          path_style: this.storageConfig.pathStyle,
        },
        entities: this.selectedGroups.map((group) => ({ full_path: group.fullPath })),
      };
    },
  },
  watch: {
    selectedGroupsCount() {
      this.showSelectError = false;
    },
  },

  methods: {
    async submitForm() {
      this.isSubmitting = true;
      this.submissionError = '';

      try {
        await axios.post(buildApiUrl('/api/:version/offline_exports'), this.exportPayload);
        this.hasSubmitSucceeded = true;
      } catch (error) {
        const status = error.response?.status;
        const serverMessage = this.extractErrorMessage(error);
        const isKnownRejection =
          (status === HTTP_STATUS_UNPROCESSABLE_ENTITY ||
            status === HTTP_STATUS_TOO_MANY_REQUESTS) &&
          Boolean(serverMessage);

        if (isKnownRejection) {
          this.submissionError = serverMessage;
          this.isRetryBlocked = true;
        } else {
          this.submissionError = s__(
            'OfflineTransferExport|Something went wrong. Try again later.',
          );
          captureException(error);
        }
      } finally {
        this.isSubmitting = false;
      }
    },
    extractErrorMessage(error) {
      const message = error.response?.data?.message;

      if (typeof message === 'string' && message) return message;
      if (typeof message?.error === 'string' && message.error) return message.error;
      return null;
    },
    onSearch(searchTerm) {
      this.search = searchTerm;
      this.startCursor = null;
      this.endCursor = null;
    },
    onRetry() {
      this.showFetchError = false;
      this.$apollo.queries.offlineTransferSourceOwnedGroups.refetch().catch(() => {});
    },
    isGroupSelected(group) {
      return this.selectedGroups.some((selected) => selected.id === group.id);
    },
    addGroup(group) {
      this.selectedGroups = [...this.selectedGroups, group];
    },
    removeGroup(group) {
      this.selectedGroups = this.selectedGroups.filter((selected) => selected.id !== group.id);
    },
    onToggleGroup(group) {
      if (this.isGroupSelected(group)) {
        this.removeGroup(group);
      } else {
        this.addGroup(group);
      }
    },
    onStepChanged({ previousTabIndex }) {
      // clear the validation error of the step being left
      this.resetStepError(previousTabIndex);
    },
    onSelectAllCurrentPage() {
      const newSelections = this.currentPageGroups.filter((group) => !this.isGroupSelected(group));
      this.selectedGroups = [...this.selectedGroups, ...newSelections];
    },
    onDeselectAll() {
      this.selectedGroups = [];
    },
    onNext(endCursor) {
      this.startCursor = null;
      this.endCursor = endCursor;
    },
    onPrev(startCursor) {
      this.startCursor = startCursor;
      this.endCursor = null;
    },
    onValidationFailed(stepIndex) {
      if (stepIndex === 0) {
        this.showSelectError = true;
      } else if (stepIndex === 1) {
        this.showStorageConfigError = true;
      }
    },

    resetStepError(stepIndex) {
      if (stepIndex === 0) {
        this.showSelectError = false;
      } else if (stepIndex === 1) {
        this.showStorageConfigError = false;
      } else if (stepIndex === 2) {
        this.submissionError = '';
        this.isRetryBlocked = false;
      }
    },
    validateStep(stepIndex) {
      // each tab/step has a unique validation logic passed to formstepper that prevents
      // continuing to the next tab
      switch (stepIndex) {
        case 0:
          return this.selectedGroupsCount > 0;
        case 1:
          return isStorageConfigValid(this.storageConfig);
        case 2:
          return true;
        default:
          return false;
      }
    },
  },
  STEPS: OFFLINE_EXPORT_TAB_HEADINGS,
};
</script>

<template>
  <div>
    <header class="gl-my-5">
      <h1 class="gl-heading-display">
        {{ s__('OfflineTransferExport|Export for offline transfer') }}
      </h1>
      <p class="gl-max-w-2xl">
        {{
          s__(
            'OfflineTransferExport|Export your groups to an AWS S3 storage service you control. You can import them to any GitLab instance, even without a network connection between this instance and the destination instance. Each group is exported with all of its subgroups and projects.',
          )
        }}
      </p>
    </header>

    <form-stepper
      :steps="$options.STEPS"
      :validate-step="validateStep"
      :can-start="canStart"
      :completion-button-text="s__('OfflineTransferExport|Start export')"
      :is-form-complete="hasSubmitSucceeded"
      :is-submitting="isSubmitting"
      :is-completion-disabled="isRetryBlocked"
      @stepped-back="onStepChanged"
      @stepped-forward="onStepChanged"
      @validation-failed="onValidationFailed"
      @complete="submitForm"
    >
      <template #step-0>
        <h2 class="gl-heading-3">
          {{ s__('OfflineTransferExport|Select groups to export') }}
        </h2>
        <select-groups-tab
          :current-page-groups="currentPageGroups"
          :selected-ids="selectedGroupIds"
          :loading="isLoading"
          :initial-loading="isInitialLoading"
          :page-info="pageInfo"
          :show-select-error="showSelectError"
          :has-fetch-error="showFetchError"
          :search-term="search"
          @toggle="onToggleGroup"
          @select-current-page="onSelectAllCurrentPage"
          @deselect-all="onDeselectAll"
          @next="onNext"
          @prev="onPrev"
          @search="onSearch"
          @retry-fetch="onRetry"
        />
      </template>

      <template #step-1>
        <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Enter AWS credentials') }}</h2>
        <export-config-tab v-model="storageConfig" :validation-attempted="showStorageConfigError" />
      </template>

      <template #step-2>
        <h2 v-if="!hasSubmitSucceeded" class="gl-heading-3">
          {{ s__('OfflineTransferExport|Review and export') }}
        </h2>
        <review-export-tab
          :selected-groups="selectedGroups"
          :bucket-name="storageConfig.bucketName"
          :has-submit-succeeded="hasSubmitSucceeded"
          :submission-error="submissionError"
        />
      </template>
    </form-stepper>
  </div>
</template>
