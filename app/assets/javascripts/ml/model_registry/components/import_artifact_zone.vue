<script>
import {
  GlLoadingIcon,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlInputGroupText,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '../services/upload_model';

const emptyValue = {
  file: null,
  subfolder: '',
};

export default {
  name: 'ImportArtifactZone',
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlLoadingIcon,
    GlInputGroupText,
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
      type: Object,
      required: false,
      default: () => emptyValue,
    },
  },
  data() {
    return {
      file: this.value.file,
      subfolder: this.value.subfolder,
      loading: false,
    };
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.file.size);
    },
    fileFullpath() {
      return joinPaths(encodeURIComponent(this.subfolder), encodeURIComponent(this.file.name));
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
      uploadModel({ importPath, file: this.file, subfolder: this.subfolder })
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

      this.$emit('input', { file, subfolder: this.subfolder });
    },
  },
  i18n: {
    dropToStartMessage: s__('MlModelRegistry|Drop to start upload'),
    uploadSingleMessage: s__(
      'MlModelRegistry|Drop or %{linkStart}select%{linkEnd} artifact to attach',
    ),
    errorMessage: s__('MlModelRegistry|Error importing artifact. Please try again.'),
    submitErrorMessage: s__('MlModelRegistry|Nothing to submit. Please try again.'),
    subfolderPrependText: s__('MlModelRegistry|Upload files under path: '),
  },
  validFileMimetypes: [],
};
</script>
<template>
  <div class="gl-p-5">
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
        class="card upload-dropzone-card upload-dropzone-border gl-w-full gl-h-full gl-align-items-center gl-justify-content-center gl-p-3"
      >
        <gl-loading-icon v-if="loading" class="gl-p-5" size="sm" />
        <div data-testid="formatted-file-size">{{ formattedFileSize }}</div>
        <div data-testid="file-name">{{ fileFullpath }}</div>
      </div>
    </upload-dropzone>
    <gl-form-group label-for="subfolderId">
      <div>
        <gl-form-input-group label-class="gl-m-0! gl-p-0!">
          <gl-form-input
            id="subfolderId"
            v-model="subfolder"
            data-testid="subfolderId"
            autocomplete="off"
            class="gl-mb-5"
          />

          <template #prepend>
            <gl-input-group-text class="gl-p-5 gl-m-0!">
              {{ $options.i18n.subfolderPrependText }}
            </gl-input-group-text>
          </template>
        </gl-form-input-group>
      </div>
    </gl-form-group>
  </div>
</template>
