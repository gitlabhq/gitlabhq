<script>
import {
  GlAlert,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlIcon,
  GlProgressBar,
  GlTooltip,
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
    GlIcon,
    GlTooltip,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlProgressBar,
    UploadDropzone,
  },
  directives: {
    'gl-tooltip': GlTooltip,
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
      alert: null,
      progressLoaded: null,
      progressTotal: null,
    };
  },
  computed: {
    formattedFileSize() {
      return numberToHumanSize(this.file.size);
    },
    formattedProgressLoaded() {
      return `${numberToHumanSize(this.progressLoaded)} / ${numberToHumanSize(this.progressTotal)}`;
    },
    fileFullpath() {
      return joinPaths(encodeURIComponent(this.subfolder), encodeURIComponent(this.file.name));
    },
    progressPercentage() {
      return Math.round((this.progressLoaded * 100) / this.progressTotal);
    },
    loading() {
      return this.progressLoaded !== null;
    },
    subfolderValid() {
      return !(this.subfolder && !/^\S+$/.test(this.subfolder));
    },
  },
  methods: {
    resetFile() {
      this.progressTotal = null;
      this.progressLoaded = null;
      this.discardFile();
    },
    onUploadProgress(progressEvent) {
      this.progressTotal = progressEvent.total;
      this.progressLoaded = progressEvent.loaded;
    },
    submitRequest(importPath) {
      this.progressLoaded = 0;
      this.progressTotal = this.file.size;
      uploadModel({
        importPath,
        file: this.file,
        subfolder: this.subfolder,
        maxAllowedFileSize: this.maxAllowedFileSize,
        onUploadProgress: this.onUploadProgress,
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
    subfolderLabel: s__('MlModelRegistry|Subfolder (optional)'),
    successfulUpload: s__('MlModelRegistry|Uploaded files successfully'),
    subfolderPlaceholder: s__('MlModelRegistry|folder name'),
    subfolderTooltip: s__(
      "MlModelRegistry|Provide a subfolder name to organize your artifacts. Entering an existing subfolder's name will place artifacts in the existing folder",
    ),
    subfolderInvalid: s__('MlModelRegistry|Subfolder cannot contain spaces'),
    subfolderDescription: s__('MlModelRegistry|Enter a subfolder name to organize your artifacts.'),
  },
  validFileMimetypes: [],
};
</script>
<template>
  <div class="gl-p-5">
    <gl-form-group
      label-for="subfolderId"
      data-testid="subfolderGroup"
      :state="subfolderValid"
      :invalid-feedback="$options.i18n.subfolderInvalid"
      :description="subfolderValid ? $options.i18n.subfolderDescription : ''"
    >
      <div>
        <label for="subfolderId" class="gl-font-weight-bold" data-testid="subfolderLabel">{{
          $options.i18n.subfolderLabel
        }}</label>
        <gl-icon id="toolTipSubfolderId" v-gl-tooltip name="information-o" tabindex="0" />
        <gl-tooltip target="toolTipSubfolderId">
          {{ $options.i18n.subfolderTooltip }}
        </gl-tooltip>
        <gl-form-input-group label-class="!gl-m-0 !gl-p-0">
          <gl-form-input
            id="subfolderId"
            v-model="subfolder"
            data-testid="subfolderId"
            autocomplete="off"
            class="gl-mb-5"
            :placeholder="$options.i18n.subfolderPlaceholder"
            @input="changeSubfolder"
          />
        </gl-form-input-group>
      </div>
    </gl-form-group>
    <upload-dropzone
      single-file-selection
      :valid-file-mimetypes="$options.validFileMimetypes"
      :upload-single-message="$options.i18n.uploadSingleMessage"
      :drop-to-start-message="$options.i18n.dropToStartMessage"
      :is-file-valid="() => true"
      @change="uploadFile"
    >
      <gl-alert v-if="file" variant="success" :dismissible="!loading" @dismiss="discardFile">
        <gl-progress-bar v-if="progressLoaded" :value="progressPercentage" />
        <div v-if="progressLoaded" data-testid="formatted-progress">
          {{ formattedProgressLoaded }}
        </div>
        <div v-else data-testid="formatted-file-size">{{ formattedFileSize }}</div>
        <div data-testid="file-name">{{ fileFullpath }}</div>
      </gl-alert>
      <gl-alert v-if="alert" :variant="alert.variant" :dismissible="true" @dismiss="hideAlert">
        {{ alert.message }}
      </gl-alert>
    </upload-dropzone>
  </div>
</template>
