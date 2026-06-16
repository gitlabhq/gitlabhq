<script>
import { GlAlert, GlFormCheckbox } from '@gitlab/ui';
import FormStepper from '~/import/offline_transfer/components/form_stepper.vue';
import SelectGroupsTab from '~/import/offline_transfer/components/select_groups_tab.vue';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import { OFFLINE_EXPORT_STEPS } from '../constants';

export default {
  name: 'OfflineTransferExportApp',
  components: {
    FormStepper,
    SelectGroupsTab,
    GlAlert,
    GlFormCheckbox,
  },
  data() {
    return {
      offlineTransferSourceOwnedGroups: null,
      showValidationError: false,
      isFormComplete: false,

      isStepComplete: {
        select: false,
        configure: false,
        review: false,
        export: false,
      },
      showFetchError: false,
      search: null,
      cursor: null,
      selectedGroups: [],
    };
  },

  apollo: {
    offlineTransferSourceOwnedGroups: {
      query: offlineTransferSourceOwnedGroupsQuery,
      update(data) {
        return data.groups;
      },
      variables() {
        return {
          search: this.search,
          after: this.cursor,
        };
      },
      error() {
        this.showFetchError = true;
      },
    },
  },

  computed: {
    groups() {
      return this.offlineTransferSourceOwnedGroups?.nodes ?? [];
    },
    selectedGroupIds() {
      return this.selectedGroups.map((group) => group.id);
    },
    isLoading() {
      return this.$apollo.queries.offlineTransferSourceOwnedGroups.loading;
    },
  },

  methods: {
    onComplete() {
      this.isFormComplete = true;
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

    onSelectAll() {
      this.selectedGroups = [...this.groups];
    },
    onDeselectAll() {
      this.selectedGroups = [];
    },
    onValidationFailed() {
      this.showValidationError = true;
    },
    validateStep(stepIndex) {
      // each tab/step has a unique validation logic
      // passed down to formstepper that if false prevents
      // continuing to the next tab
      switch (stepIndex) {
        case 0:
          return this.selectedGroups.length > 0;
        case 1:
          return this.isStepComplete.configure;
        case 2:
          return this.isStepComplete.review;
        case 3:
          return this.isStepComplete.export;
        default:
          return false;
      }
    },
    onSteppedBack({ previousTabIndex }) {
      const fields = ['select', 'configure', 'review', 'export'];
      // stepping back resets the valid state of previous tab
      // in case user makes changes
      this.isStepComplete[fields[previousTabIndex]] = false;
    },
  },
  STEPS: OFFLINE_EXPORT_STEPS,
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
            'OfflineTransferExport|Export your groups to an AWS S3 storage service you control. You can import them to any GitLab instance, even without a network connection between this instance and the destination instance.',
          )
        }}
      </p>
      <!-- // temporary alerts, to be replaced-->
      <gl-alert
        v-if="showFetchError"
        :title="__('Error')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="danger"
        data-testid="fetch-error-alert"
        @dismiss="showFetchError = false"
      >
        {{ s__('OfflineTransferExport|Could not load groups. Please try again.') }}
      </gl-alert>

      <gl-alert
        v-if="isFormComplete"
        :title="__('Complete')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="info"
        data-testid="completion-alert"
        @dismiss="isFormComplete = false"
      />
      <gl-alert
        v-if="showValidationError"
        :title="__('Error')"
        :dismiss-label="__('Dismiss')"
        dismissible
        variant="danger"
        data-testid="validation-alert"
        @dismiss="showValidationError = false"
      />
    </header>

    <form-stepper
      :steps="$options.STEPS"
      :validate-step="validateStep"
      :completion-button-text="s__('OfflineTransferExport|Start export')"
      @stepped-back="onSteppedBack"
      @validation-failed="onValidationFailed"
      @complete="onComplete"
    >
      <template #step-0>
        <h2 class="gl-heading-3">
          {{ s__('OfflineTransferExport|Select groups to export') }}
        </h2>
        <p>
          {{
            s__(
              'OfflineTransferExport|Each group is exported with all of its subgroups and projects.',
            )
          }}
        </p>
        <select-groups-tab
          :groups="groups"
          :selected-ids="selectedGroupIds"
          :loading="isLoading"
          @toggle="onToggleGroup"
          @select-all="onSelectAll"
          @deselect-all="onDeselectAll"
        />
      </template>

      <template #step-1>
        <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Export configuration') }}</h2>
        <gl-form-checkbox v-model="isStepComplete.configure" />
      </template>

      <template #step-2>
        <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Review export') }}</h2>
        <gl-form-checkbox v-model="isStepComplete.review" />
      </template>

      <template #step-3>
        <h2 class="gl-heading-3">{{ s__('OfflineTransferExport|Export') }}</h2>
        <gl-form-checkbox v-model="isStepComplete.export" />
      </template>
    </form-stepper>
  </div>
</template>
