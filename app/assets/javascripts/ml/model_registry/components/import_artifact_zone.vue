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
import { __, s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '../services/upload_model';
import { UPLOAD_STATUS as STATUS } from '../constants';

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
      uploads: [],
      states: [],
      loads: [],
      errors: [],
      subfolder: '',
    };
  },
  computed: {
    subfolderValid() {
      return !(this.subfolder && !/^\S+$/.test(this.subfolder));
    },
    allCompleted() {
      return this.states.every(
        (s) => s === STATUS.FAILED || s === STATUS.CANCELED || s === STATUS.SUCCEEDED,
      );
    },
    allErrors() {
      return this.uploads
        .map((upload, index) => {
          return this.errors[index] ? `${upload.file.name}: ${this.errors[index]}` : null;
        })
        .filter(Boolean)
        .join(' ');
    },
    alert() {
      if (!this.states.length) {
        return null;
      }
      const someRunning = this.states.some((s) => s === STATUS.CREATING || s === STATUS.PROCESSING);

      if (someRunning) {
        return null;
      }

      const allSucceeded = this.states.every((s) => s === STATUS.SUCCEEDED);
      if (allSucceeded) {
        return {
          message: this.$options.i18n.allSucceeded,
          variant: 'success',
        };
      }

      const allFailedOrCanceled = this.states.every(
        (s) => s === STATUS.FAILED || s === STATUS.CANCELED,
      );
      if (allFailedOrCanceled) {
        return {
          message: this.$options.i18n.allFailedOrCanceled,
          variant: 'danger',
        };
      }
      return {
        message: this.$options.i18n.someFailed,
        variant: 'warning',
      };
    },
  },
  methods: {
    setError(index, message) {
      this.errors.splice(index, 1, message);
      this.$emit('error', this.allErrors);
    },
    buildUploads(files) {
      this.states = new Array(files.length).fill(STATUS.CREATING);
      this.loads = new Array(files.length).fill(0);
      this.errors = new Array(files.length).fill(null);

      this.uploads = Array.from(files).map((file, index) => {
        const upload = {
          file,
          total: file.size,
          axiosSource: axios.CancelToken.source(),
          formattedFileSize: numberToHumanSize(file.size),
          fullPath: joinPaths(encodeURIComponent(this.subfolder), encodeURIComponent(file.name)),
        };
        upload.cancelUpload = () => {
          if (this.states[index] === STATUS.PROCESSING) {
            upload.axiosSource.cancel();
          } else if (this.states[index] === STATUS.CREATING) {
            this.states.splice(index, 1, STATUS.CANCELED);
            this.setError(index, this.$options.i18n.cancelMessage);
          }
        };
        upload.onUploadProgress = (event) => {
          this.loads.splice(index, 1, event.loaded);
        };
        upload.progressPercentage = () => {
          return Math.round((this.loads[index] * 100) / upload.total);
        };
        upload.formattedProgressLoaded = () => {
          return `${numberToHumanSize(this.loads[index])} / ${numberToHumanSize(upload.total)}`;
        };
        upload.isCancelable = () => {
          return (
            (this.states[index] === STATUS.CREATING || this.states[index] === STATUS.PROCESSING) &&
            upload.progressPercentage() < 100
          );
        };
        upload.loading = () => this.states[index] === STATUS.PROCESSING;
        upload.succeeded = () => this.states[index] === STATUS.SUCCEEDED;
        upload.failed = () => this.states[index] === STATUS.FAILED;
        upload.canceled = () => this.states[index] === STATUS.CANCELED;

        return upload;
      });
      this.files = [];
    },
    uploadArtifact(importPath) {
      this.states = this.states.map((state) => {
        if (state === STATUS.CREATING) {
          return STATUS.PROCESSING;
        }

        return state;
      });
      return Promise.allSettled(
        this.uploads.map((upload, index) => this.uploadSingle(importPath, upload, index)),
      ).then(() => this.$emit('change'));
    },
    uploadSingle(importPath, upload, index) {
      if (this.states[index] !== STATUS.PROCESSING) {
        return Promise.resolve();
      }
      return uploadModel({
        importPath,
        file: upload.file,
        subfolder: this.subfolder,
        maxAllowedFileSize: this.maxAllowedFileSize,
        onUploadProgress: upload.onUploadProgress,
        cancelToken: upload.axiosSource.token,
      })
        .then(() => {
          this.states.splice(index, 1, STATUS.SUCCEEDED);
        })
        .catch((error) => {
          if (axios.isCancel(error)) {
            this.states.splice(index, 1, STATUS.CANCELED);
            this.setError(index, this.$options.i18n.cancelMessage);
          } else {
            this.states.splice(index, 1, STATUS.FAILED);
            this.setError(index, error);
          }
        });
    },
    changeSubfolder(subfolder) {
      this.subfolder = subfolder;
    },
    changeFile(files) {
      this.buildUploads(files);
      if (this.submitOnSelect && this.path) {
        this.uploadArtifact(this.path);
      }
    },
    reset() {
      this.uploads = [];
      this.states = [];
      this.loads = [];
      this.errors = [];
      this.subfolder = '';
    },
  },
  i18n: {
    dropToStartMessage: s__('MlModelRegistry|Drop to start upload'),
    cancelMessage: s__('MlModelRegistry|User canceled upload.'),
    cancelButtonText: __('Cancel'),
    clearButtonText: __('Clear uploads'),
    uploadMessage: s__('MlModelRegistry|Drop or %{linkStart}select%{linkEnd} artifacts to attach'),
    subfolderLabel: s__('MlModelRegistry|Subfolder'),
    allSucceeded: s__('MlModelRegistry|Artifacts uploaded successfully.'),
    allFailedOrCanceled: s__('MlModelRegistry|All artifact uploads failed or were canceled.'),
    someFailed: s__('MlModelRegistry|Artifact uploads completed with errors.'),
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
      :valid-file-mimetypes="$options.validFileMimetypes"
      :upload-multiple-message="$options.i18n.uploadMessage"
      :drop-to-start-message="$options.i18n.dropToStartMessage"
      :is-file-valid="() => true"
      @change="changeFile"
    >
      <div v-if="uploads.length">
        <div v-for="(upload, index) in uploads" :key="index" class="py-3 gl-border-b">
          <div class="row">
            <div :data-testid="`file-name-${index}`" class="col-md-4">{{ upload.fullPath }}</div>
            <gl-progress-bar
              :data-testid="`progress-${index}`"
              :value="upload.progressPercentage()"
              class="col-md-4 mt-3 px-0"
            />
            <div
              v-if="upload.loading()"
              :data-testid="`formatted-progress-${index}`"
              class="col-md-2 text-right"
            >
              {{ upload.formattedProgressLoaded() }}
            </div>
            <div v-else :data-testid="`formatted-file-size-${index}`" class="col-md-2 text-right">
              {{ upload.formattedFileSize }}
            </div>
            <div class="col-md-2 text-right">
              <gl-button
                v-if="upload.isCancelable()"
                :data-testid="`cancel-button-${index}`"
                category="secondary"
                variant="danger"
                class="mb-2"
                @click="upload.cancelUpload"
                >{{ $options.i18n.cancelButtonText }}
              </gl-button>
              <gl-icon v-if="upload.succeeded()" name="status_success" variant="success" />
              <gl-icon v-if="upload.failed()" name="status_failed" variant="danger" />
              <gl-icon v-if="upload.canceled()" name="status_canceled" variant="warning" />
            </div>
          </div>
          <p v-if="errors[index]" :data-testid="`fb-${index}`" class="row m-0 p-0 gl-text-subtle">
            {{ errors[index] }}
          </p>
        </div>
        <gl-button
          v-if="allCompleted"
          data-testid="clear-button"
          category="secondary"
          class="gl-mt-3"
          @click="reset"
        >
          {{ $options.i18n.clearButtonText }}
        </gl-button>
      </div>
    </upload-dropzone>
    <gl-alert
      v-if="alert"
      data-testid="alert"
      :variant="alert.variant"
      class="gl-mt-3"
      @dismiss="reset"
    >
      {{ alert.message }}
    </gl-alert>
  </div>
</template>
