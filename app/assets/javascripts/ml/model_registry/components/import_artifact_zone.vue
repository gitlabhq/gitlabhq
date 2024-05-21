<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { contentTypeMultipartFormData } from '~/lib/utils/headers';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';

export default {
  name: 'ImportArtifactZone',
  components: {
    GlLoadingIcon,
    UploadDropzone,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      file: null,
      loading: false,
    };
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.file.size);
    },
    importUrl() {
      return joinPaths(this.path, encodeURIComponent(this.file.name));
    },
  },
  methods: {
    resetFile() {
      this.file = null;
      this.loading = false;
    },
    submitRequest() {
      const formData = new FormData();
      formData.append('file', this.file);
      return axios
        .put(this.importUrl, formData, {
          headers: {
            ...contentTypeMultipartFormData,
          },
        })
        .then(() => {
          this.$emit('change');
          this.resetFile();
        })
        .catch(() => {
          this.resetFile();
          createAlert({ message: this.$options.i18n.errorMessage });
        });
    },
    uploadFile(file) {
      this.file = file;
      this.loading = true;

      return this.submitRequest();
    },
  },
  i18n: {
    dropToStartMessage: s__('MlModelRegistry|Drop to start upload'),
    uploadSingleMessage: s__(
      'MlModelRegistry|Drop or %{linkStart}select%{linkEnd} artifact to attach',
    ),
    errorMessage: s__('MlModelRegistry|Error importing artifact. Please try again.'),
  },
  validFileMimetypes: [],
};
</script>
<template>
  <upload-dropzone
    single-file-selection
    display-as-card
    :valid-file-mimetypes="$options.validFileMimetypes"
    :upload-single-message="$options.i18n.uploadSingleMessage"
    :drop-to-start-message="$options.i18n.dropToStartMessage"
    :is-file-valid="() => true"
    @change="uploadFile"
  >
    <div
      v-if="file"
      class="card upload-dropzone-card upload-dropzone-border gl-w-full gl-h-full align-items-center justify-content-center gl-p-3"
    >
      <gl-loading-icon class="gl-p-5" size="sm" />
      <div data-testid="formatted-file-size">{{ formattedFileSize }}</div>
      <div data-testid="file-name">{{ file.name }}</div>
    </div>
  </upload-dropzone>
</template>
