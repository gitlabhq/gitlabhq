<script>
import {
  GlAlert,
  GlButton,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlPagination,
  GlSprintf,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { helpPagePath } from '~/helpers/help_page_helper';
import httpStatusCodes from '~/lib/utils/http_status';
import { __, s__, sprintf } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlPagination,
    GlSprintf,
    GlTable,
    TimeagoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  inject: ['projectId', 'admin', 'fileSizeLimit'],
  docsLink: helpPagePath('ci/secure_files/index'),
  DEFAULT_PER_PAGE,
  i18n: {
    deleteLabel: __('Delete File'),
    uploadLabel: __('Upload File'),
    uploadingLabel: __('Uploading...'),
    pagination: {
      next: __('Next'),
      prev: __('Prev'),
    },
    title: __('Secure Files'),
    overviewMessage: __(
      'Use Secure Files to store files used by your pipelines such as Android keystores, or Apple provisioning profiles and signing certificates.',
    ),
    moreInformation: __('More information'),
    uploadErrorMessages: {
      duplicate: __('A file with this name already exists.'),
      tooLarge: __('File too large. Secure Files must be less than %{limit} MB.'),
    },
    deleteModalTitle: s__('SecureFiles|Delete %{name}?'),
    deleteModalMessage: s__(
      'SecureFiles|Secure File %{name} will be permanently deleted. Are you sure?',
    ),
    deleteModalButton: s__('SecureFiles|Delete secure file'),
  },
  deleteModalId: 'deleteModalId',
  data() {
    return {
      page: 1,
      totalItems: 0,
      loading: false,
      uploading: false,
      error: false,
      errorMessage: null,
      projectSecureFiles: [],
      deleteModalFileId: null,
      deleteModalFileName: null,
    };
  },
  fields: [
    {
      key: 'name',
      label: __('Filename'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'created_at',
      label: __('Uploaded'),
      tdClass: 'gl-vertical-align-middle!',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-text-right gl-vertical-align-middle!',
    },
  ],
  computed: {
    fields() {
      return this.$options.fields;
    },
  },
  watch: {
    page(newPage) {
      this.getProjectSecureFiles(newPage);
    },
  },
  created() {
    this.getProjectSecureFiles();
  },
  methods: {
    async deleteSecureFile(secureFileId) {
      this.loading = true;
      this.error = false;
      try {
        await Api.deleteProjectSecureFile(this.projectId, secureFileId);
        this.getProjectSecureFiles();
      } catch (error) {
        Sentry.captureException(error);
        this.error = true;
        this.errorMessage = error;
      }
    },
    async getProjectSecureFiles(page) {
      this.loading = true;
      const response = await Api.projectSecureFiles(this.projectId, { page });

      this.totalItems = parseInt(response.headers?.['x-total'], 10) || 0;

      this.projectSecureFiles = response.data;

      this.loading = false;
      this.uploading = false;
    },
    async uploadSecureFile() {
      this.error = null;
      this.uploading = true;
      const [file] = this.$refs.fileUpload.files;
      try {
        await Api.uploadProjectSecureFile(this.projectId, this.uploadFormData(file));
        this.getProjectSecureFiles();
      } catch (error) {
        this.error = true;
        this.errorMessage = this.formattedErrorMessage(error);
        this.uploading = false;
      }
    },
    formattedErrorMessage(error) {
      let message = '';
      if (error?.response?.data?.message?.name) {
        message = this.$options.i18n.uploadErrorMessages.duplicate;
      } else if (error.response.status === httpStatusCodes.PAYLOAD_TOO_LARGE) {
        message = sprintf(this.$options.i18n.uploadErrorMessages.tooLarge, {
          limit: this.fileSizeLimit,
        });
      } else {
        Sentry.captureException(error);
        message = error;
      }
      return message;
    },
    loadFileSelctor() {
      this.$refs.fileUpload.click();
    },
    setDeleteModalData(secureFile) {
      this.deleteModalFileId = secureFile.id;
      this.deleteModalFileName = secureFile.name;
    },
    uploadFormData(file) {
      const formData = new FormData();
      formData.append('name', file.name);
      formData.append('file', file);

      return formData;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" class="gl-mt-6" @dismiss="error = null">
      {{ errorMessage }}
    </gl-alert>
    <div class="row">
      <div class="col-md-12 col-lg-6 gl-display-flex">
        <div class="gl-flex-direction-column gl-flex-wrap">
          <h1 class="gl-font-size-h1 gl-mt-3 gl-mb-0">
            {{ $options.i18n.title }}
          </h1>
        </div>
      </div>

      <div class="col-md-12 col-lg-6">
        <div class="gl-display-flex gl-flex-wrap gl-justify-content-end">
          <gl-button v-if="admin" class="gl-mt-3" variant="confirm" @click="loadFileSelctor">
            <span v-if="uploading">
              <gl-loading-icon size="sm" class="gl-my-5" inline />
              {{ $options.i18n.uploadingLabel }}
            </span>
            <span v-else>
              <gl-icon name="upload" class="gl-mr-2" /> {{ $options.i18n.uploadLabel }}
            </span>
          </gl-button>
          <input
            id="file-upload"
            ref="fileUpload"
            type="file"
            class="hidden"
            data-qa-selector="file_upload_field"
            @change="uploadSecureFile"
          />
        </div>
      </div>
    </div>

    <div class="row">
      <div class="col-md-12 col-lg-12 gl-my-4">
        <span data-testid="info-message">
          {{ $options.i18n.overviewMessage }}
          <gl-link :href="$options.docsLink" target="_blank">{{
            $options.i18n.moreInformation
          }}</gl-link>
        </span>
      </div>
    </div>

    <gl-table
      :busy="loading"
      :fields="fields"
      :items="projectSecureFiles"
      tbody-tr-class="js-ci-secure-files-row"
      data-qa-selector="ci_secure_files_table_content"
      sort-by="key"
      sort-direction="asc"
      stacked="lg"
      table-class="text-secondary"
      show-empty
      sort-icon-left
      no-sort-reset
    >
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
      </template>

      <template #cell(name)="{ item }">
        {{ item.name }}
      </template>

      <template #cell(created_at)="{ item }">
        <timeago-tooltip :time="item.created_at" />
      </template>

      <template #cell(actions)="{ item }">
        <gl-button
          v-if="admin"
          v-gl-modal="$options.deleteModalId"
          v-gl-tooltip.hover.top="$options.i18n.deleteLabel"
          variant="danger"
          icon="remove"
          :aria-label="$options.i18n.deleteLabel"
          @click="setDeleteModalData(item)"
        />
      </template>
    </gl-table>

    <gl-pagination
      v-if="!loading"
      v-model="page"
      :per-page="$options.DEFAULT_PER_PAGE"
      :total-items="totalItems"
      :next-text="$options.i18n.pagination.next"
      :prev-text="$options.i18n.pagination.prev"
      align="center"
    />

    <gl-modal
      :ref="$options.deleteModalId"
      :modal-id="$options.deleteModalId"
      title-tag="h4"
      category="primary"
      :ok-title="$options.i18n.deleteModalButton"
      ok-variant="danger"
      @ok="deleteSecureFile(deleteModalFileId)"
    >
      <template #modal-title>
        <gl-sprintf :message="$options.i18n.deleteModalTitle">
          <template #name>{{ deleteModalFileName }}</template>
        </gl-sprintf>
      </template>

      <gl-sprintf :message="$options.i18n.deleteModalMessage">
        <template #name>{{ deleteModalFileName }}</template>
      </gl-sprintf>
    </gl-modal>
  </div>
</template>
