<script>
import {
  GlAlert,
  GlButton,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlIcon,
  GlProgressBar,
  GlTooltip,
} from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '../services/upload_model';

export default {
  name: 'ImportArtifactZone',
  components: {
    GlAlert,
    GlButton,
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
  },
  data() {
    return {
      file: null,
      subfolder: '',
      alert: null,
      progressLoaded: null,
      progressTotal: null,
      axiosSource: null,
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
    uploadArtifact(importPath) {
      this.progressLoaded = 0;
      this.progressTotal = this.file.size;
      this.axiosSource = axios.CancelToken.source();
      uploadModel({
        importPath,
        file: this.file,
        subfolder: this.subfolder,
        maxAllowedFileSize: this.maxAllowedFileSize,
        onUploadProgress: this.onUploadProgress,
        cancelToken: this.axiosSource.token,
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
    changeSubfolder(subfolder) {
      this.subfolder = subfolder;
    },
    changeFile(file) {
      this.file = file;

      if (this.submitOnSelect && this.path) {
        this.uploadArtifact(this.path);
      }
    },
    hideAlert() {
      this.alert = null;
    },
    cancelUpload() {
      if (this.axiosSource) {
        this.axiosSource.cancel(this.$options.i18n.cancelMessage);
        this.axiosSource = null;
      }
      this.discardFile();
    },
    discardFile() {
      this.file = null;
      this.subfolder = '';
    },
  },
  i18n: {
    dropToStartMessage: s__('MlModelRegistry|Drop to start upload'),
    cancelMessage: s__('MlModelRegistry|User canceled upload.'),
    cancelButtonText: s__('MlModelRegistry|Cancel upload'),
    uploadSingleMessage: s__(
      'MlModelRegistry|Drop or %{linkStart}select%{linkEnd} artifact to attach',
    ),
    subfolderLabel: s__('MlModelRegistry|Subfolder'),
    successfulUpload: s__('MlModelRegistry|Uploaded files successfully'),
    subfolderPlaceholder: s__('MlModelRegistry|folder name'),
    subfolderTooltip: s__(
      "MlModelRegistry|Provide a subfolder name to organize your artifacts. Entering an existing subfolder's name will place artifacts in the existing folder",
    ),
    subfolderInvalid: s__('MlModelRegistry|Subfolder cannot contain spaces'),
    subfolderDescription: s__('MlModelRegistry|Enter a subfolder name to organize your artifacts.'),
    optionalText: s__('MlModelRegistry|(Optional)'),
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
        <label for="subfolderId" class="gl-font-bold" data-testid="subfolderLabel">{{
          $options.i18n.subfolderLabel
        }}</label>
        <label class="gl-font-normal" data-testid="subfolderLabelOptional">{{
          $options.i18n.optionalText
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
      @change="changeFile"
    >
      <div v-if="file" class="upload-dropzone-border p-3">
        <gl-progress-bar v-if="progressLoaded" :value="progressPercentage" />
        <div v-if="progressLoaded" data-testid="formatted-progress">
          {{ formattedProgressLoaded }}
        </div>
        <div v-else data-testid="formatted-file-size">{{ formattedFileSize }}</div>
        <div data-testid="file-name">{{ fileFullpath }}</div>
        <gl-button
          data-testid="cancel-upload-button"
          category="secondary"
          class="mt-3"
          variant="danger"
          @click="cancelUpload"
          >{{ $options.i18n.cancelButtonText }}</gl-button
        >
      </div>
    </upload-dropzone>
    <gl-alert v-if="alert" :variant="alert.variant" @dismiss="hideAlert">
      {{ alert.message }}
    </gl-alert>
  </div>
</template>
