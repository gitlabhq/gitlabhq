<script>
import {
  GlAlert,
  GlLoadingIcon,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlInputGroupText,
} from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '../services/upload_model';
import { emptyArtifactFile } from '../constants';

export default {
  name: 'ImportArtifactZone',
  components: {
    GlAlert,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlLoadingIcon,
    GlInputGroupText,
    UploadDropzone,
  },
  inject: ['maxAllowedFileSize'],
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
      default: () => emptyArtifactFile,
    },
  },
  data() {
    return {
      file: this.value.file,
      subfolder: this.value.subfolder,
      loading: false,
      alert: null,
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
      this.loading = false;
      this.discardFile();
    },
    submitRequest(importPath) {
      this.loading = true;
      uploadModel({
        importPath,
        file: this.file,
        subfolder: this.subfolder,
        maxAllowedFileSize: this.maxAllowedFileSize,
      })
        .then(() => {
          this.resetFile();
          this.alert = { message: this.$options.i18n.successfulUpload, variant: 'success' };
          this.$emit('change');
        })
        .catch((error) => {
          this.resetFile();
          this.alert = { message: error, variant: 'danger' };
        });
    },
    emitInput(value) {
      this.$emit('input', { ...value });
    },
    changeSubfolder(subfolder) {
      this.subfolder = subfolder;
      this.emitInput({ file: this.file, subfolder });
    },
    uploadFile(file) {
      this.file = file;
      this.emitInput({ file, subfolder: this.subfolder });

      if (this.submitOnSelect && this.path) {
        this.submitRequest(this.path);
      }
    },
    hideAlert() {
      this.alert = null;
    },
    discardFile() {
      this.file = null;
      this.subfolder = '';
      this.emitInput(emptyArtifactFile);
    },
  },
  i18n: {
    dropToStartMessage: s__('MlModelRegistry|Drop to start upload'),
    uploadSingleMessage: s__(
      'MlModelRegistry|Drop or %{linkStart}select%{linkEnd} artifact to attach',
    ),
    subfolderPrependText: s__('MlModelRegistry|Upload files under path: '),
    successfulUpload: s__('MlModelRegistry|Uploaded files successfully'),
  },
  validFileMimetypes: [],
};
</script>
<template>
  <div class="gl-p-5">
    <upload-dropzone
      single-file-selection
      :valid-file-mimetypes="$options.validFileMimetypes"
      :upload-single-message="$options.i18n.uploadSingleMessage"
      :drop-to-start-message="$options.i18n.dropToStartMessage"
      :is-file-valid="() => true"
      @change="uploadFile"
    >
      <gl-alert v-if="file" variant="success" :dismissible="!loading" @dismiss="discardFile">
        <gl-loading-icon v-if="loading" class="gl-p-5" size="sm" />
        <div data-testid="formatted-file-size">{{ formattedFileSize }}</div>
        <div data-testid="file-name">{{ fileFullpath }}</div>
      </gl-alert>
      <gl-alert v-if="alert" :variant="alert.variant" :dismissible="true" @dismiss="hideAlert">
        {{ alert.message }}
      </gl-alert>
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
            @input="changeSubfolder"
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
