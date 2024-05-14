<script>
import { GlFormGroup, GlFormInput, GlLoadingIcon, GlModal } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { __, s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import MetricImagesTable from '~/vue_shared/components/metric_images/metric_images_table.vue';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlLoadingIcon,
    GlModal,
    MetricImagesTable,
    UploadDropzone,
  },
  inject: ['canUpdate', 'projectId', 'iid'],
  data() {
    return {
      currentFiles: [],
      isModalUrlValid: true,
      modalVisible: false,
      modalUrl: '',
      modalUrlText: '',
    };
  },
  computed: {
    ...mapState(['metricImages', 'isLoadingMetricImages', 'isUploadingImage']),
    actionPrimaryProps() {
      return {
        text: this.$options.i18n.modalUpload,
        attributes: {
          loading: this.isUploadingImage,
          disabled: this.isUploadingImage || !this.isModalUrlValid,
          category: 'primary',
          variant: 'confirm',
        },
      };
    },
  },
  mounted() {
    this.setInitialData({ modelIid: this.iid, projectId: this.projectId });
    this.fetchImages();
  },
  methods: {
    ...mapActions(['fetchImages', 'uploadImage', 'setInitialData']),
    clearInputs() {
      this.modalVisible = false;
      this.modalUrl = '';
      this.modalUrlText = '';
      this.currentFile = false;
    },
    openMetricDialog(files) {
      this.modalVisible = true;
      this.currentFiles = files;
    },
    async onUpload() {
      if (!this.isModalUrlValid) return;

      try {
        await this.uploadImage({
          files: this.currentFiles,
          url: this.modalUrl,
          urlText: this.modalUrlText,
        });
        // Error case handled within action
      } finally {
        this.clearInputs();
      }
    },
    onModalUrlInput(value) {
      if (value === '') this.validateModalUrl();
    },
    validateModalUrl() {
      try {
        this.isModalUrlValid = Boolean(new URL(this.modalUrl));
      } catch (err) {
        this.isModalUrlValid = false;
      }
    },
  },
  i18n: {
    modalUpload: __('Upload'),
    modalCancel: __('Cancel'),
    modalTitle: s__('Incidents|Add image details'),
    modalDescription: s__(
      "Incidents|Add text or a link to display with your image. If you don't add either, the file name displays instead.",
    ),
    dropDescription: s__(
      'Incidents|Drop or %{linkStart}upload%{linkEnd} a metric screenshot to attach it to the incident',
    ),
    textInputLabel: __('Text (optional)'),
    urlInputLabel: __('Link (optional)'),
    urlInputDescription: s__('Incidents|Must start with http:// or https://'),
    invalidUrlMessage: __('Invalid URL'),
  },
};
</script>

<template>
  <div>
    <div v-if="isLoadingMetricImages">
      <gl-loading-icon class="gl-p-5" size="sm" />
    </div>
    <gl-modal
      modal-id="upload-metric-modal"
      size="sm"
      :action-primary="actionPrimaryProps"
      :action-cancel="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ {
        text: $options.i18n.modalCancel,
      } /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :title="$options.i18n.modalTitle"
      :visible="modalVisible"
      @hidden="clearInputs"
      @primary.prevent="onUpload"
    >
      <p>{{ $options.i18n.modalDescription }}</p>
      <gl-form-group :label="$options.i18n.textInputLabel" label-for="upload-text-input">
        <gl-form-input id="upload-text-input" v-model="modalUrlText" />
      </gl-form-group>

      <gl-form-group
        id="upload-url-group"
        :label="$options.i18n.urlInputLabel"
        label-for="upload-url-input"
        :description="$options.i18n.urlInputDescription"
        :invalid-feedback="$options.i18n.invalidUrlMessage"
        :state="isModalUrlValid"
      >
        <gl-form-input
          id="upload-url-input"
          v-model="modalUrl"
          :state="isModalUrlValid"
          @blur="validateModalUrl"
          @input="onModalUrlInput"
        />
      </gl-form-group>
    </gl-modal>
    <metric-images-table v-for="metric in metricImages" :key="metric.id" v-bind="metric" />
    <upload-dropzone
      v-if="canUpdate"
      :drop-description-message="$options.i18n.dropDescription"
      @change="openMetricDialog"
    />
  </div>
</template>
