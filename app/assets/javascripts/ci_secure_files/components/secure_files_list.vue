<script>
import {
  GlAlert,
  GlButton,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlPagination,
  GlSprintf,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { HTTP_STATUS_PAYLOAD_TOO_LARGE } from '~/lib/utils/http_status';
import { __, s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import MetadataButton from './metadata/button.vue';
import MetadataModal from './metadata/modal.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlModal,
    GlPagination,
    GlSprintf,
    GlTable,
    TimeagoTooltip,
    MetadataButton,
    MetadataModal,
    CrudComponent,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [Tracking.mixin()],
  inject: ['projectId', 'admin', 'fileSizeLimit'],
  DEFAULT_PER_PAGE,
  i18n: {
    title: __('Files'),
    deleteLabel: __('Delete File'),
    uploadLabel: __('Upload File'),
    uploadingLabel: __('Uploading...'),
    noFilesMessage: __('There are no secure files yet.'),
    uploadErrorMessages: {
      duplicate: __('A file with this name already exists.'),
      tooLarge: __('File too large. Secure files must be less than %{limit} MB.'),
    },
    deleteModalTitle: s__('SecureFiles|Delete %{name}?'),
    deleteModalMessage: s__(
      'SecureFiles|Secure file %{name} will be permanently deleted. Are you sure?',
    ),
    deleteModalButton: s__('SecureFiles|Delete secure file'),
  },
  deleteModalId: 'deleteModalId',
  metadataModalId: 'metadataModalId',
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
      metadataSecureFile: {},
    };
  },
  fields: [
    {
      key: 'name',
      label: __('File name'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'created_at',
      label: __('Uploaded date'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'actions',
      label: __('Actions'),
      thAlignRight: true,
      tdClass: 'gl-text-right !gl-align-middle',
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

        this.track('delete_secure_file');
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
      this.track('render_secure_files_list');
    },
    async uploadSecureFile() {
      this.error = null;
      this.uploading = true;
      const [file] = this.$refs.fileUpload.files;
      try {
        await Api.uploadProjectSecureFile(this.projectId, this.uploadFormData(file));
        this.getProjectSecureFiles();
        this.track('upload_secure_file');
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
      } else if (error.response.status === HTTP_STATUS_PAYLOAD_TOO_LARGE) {
        message = sprintf(this.$options.i18n.uploadErrorMessages.tooLarge, {
          limit: this.fileSizeLimit,
        });
      } else {
        Sentry.captureException(error);
        message = error;
      }
      return message;
    },
    loadFileSelector() {
      this.$refs.fileUpload.click();
    },
    setDeleteModalData(secureFile) {
      this.deleteModalFileId = secureFile.id;
      this.deleteModalFileName = secureFile.name;
    },
    updateMetadataSecureFile(secureFile) {
      this.metadataSecureFile = secureFile;
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

    <crud-component :title="$options.i18n.title" :count="projectSecureFiles.length" icon="document">
      <template #actions>
        <gl-button v-if="admin" size="small" @click="loadFileSelector">
          <span v-if="uploading">
            <gl-loading-icon class="gl-my-5" inline />
            {{ $options.i18n.uploadingLabel }}
          </span>
          <span v-else>
            {{ $options.i18n.uploadLabel }}
          </span>
        </gl-button>
        <input
          id="file-upload"
          ref="fileUpload"
          type="file"
          class="hidden"
          @change="uploadSecureFile"
        />
      </template>
      <gl-table
        :busy="loading"
        :fields="fields"
        :items="projectSecureFiles"
        tbody-tr-class="js-ci-secure-files-row"
        sort-by="key"
        sort-direction="asc"
        stacked="md"
        table-class="gl-text-subtle"
        show-empty
        :empty-text="$options.i18n.noFilesMessage"
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
          <metadata-button
            :secure-file="item"
            :admin="admin"
            modal-id="$options.metadataModalId"
            @selectSecureFile="updateMetadataSecureFile"
          />
          <gl-button
            v-if="admin"
            v-gl-modal="$options.deleteModalId"
            v-gl-tooltip.hover.top="$options.i18n.deleteLabel"
            size="small"
            category="tertiary"
            variant="default"
            icon="remove"
            :aria-label="$options.i18n.deleteLabel"
            data-testid="delete-button"
            @click="setDeleteModalData(item)"
          />
        </template>
      </gl-table>
      <template #pagination>
        <gl-pagination
          v-if="!loading"
          v-model="page"
          :per-page="$options.DEFAULT_PER_PAGE"
          :total-items="totalItems"
          align="center"
          class="gl-mt-5"
        />
      </template>
    </crud-component>

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

    <metadata-modal
      :name="metadataSecureFile.name"
      :file-extension="metadataSecureFile.file_extension"
      :metadata="metadataSecureFile.metadata"
      modal-id="$options.metadataModalId"
    />
  </div>
</template>
