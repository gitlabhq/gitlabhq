<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '../services/upload_model';

export default {
  name: 'ImportArtifactZone',
  components: {
    GlLoadingIcon,
    UploadDropzone,
  },
  props: {
    path: {
      type: String,
      required: false,
      default: null,
    },
    submitOnSelect: {
      type: Boolean,
      required: false,
      default: true,
    },
    value: {
      type: File,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      file: this.value,
      loading: false,
    };
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.file.size);
    },
  },
  methods: {
    resetFile() {
      this.file = null;
      this.loading = false;
      this.$emit('input', null);
    },
    submitRequest(importPath) {
      this.loading = true;

      uploadModel({ importPath, file: this.file })
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

      if (this.submitOnSelect && this.path) {
        this.submitRequest(this.path);
      }

      this.$emit('input', file);
    },
  },
  i18n: {
    dropToStartMessage: s__('MlModelRegistry|Drop to start upload'),
    uploadSingleMessage: s__(
      'MlModelRegistry|Drop or %{linkStart}select%{linkEnd} artifact to attach',
    ),
    errorMessage: s__('MlModelRegistry|Error importing artifact. Please try again.'),
    submitErrorMessage: s__('MlModelRegistry|Nothing to submit. Please try again.'),
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
      <gl-loading-icon v-if="loading" class="gl-p-5" size="sm" />
      <div data-testid="formatted-file-size">{{ formattedFileSize }}</div>
      <div data-testid="file-name">{{ file.name }}</div>
    </div>
  </upload-dropzone>
</template>
