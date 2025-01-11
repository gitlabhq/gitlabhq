<script>
import { GlLink, GlSprintf, GlAnimatedUploadIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { VALID_DATA_TRANSFER_TYPE, VALID_IMAGE_FILE_MIMETYPE } from './constants';
import { isValidImage } from './utils';

export default {
  components: {
    GlLink,
    GlSprintf,
    GlAnimatedUploadIcon,
  },
  props: {
    displayAsCard: {
      type: Boolean,
      required: false,
      default: false,
    },
    enableDragBehavior: {
      type: Boolean,
      required: false,
      default: false,
    },
    uploadSingleMessage: {
      type: String,
      required: false,
      default: __('Drop or %{linkStart}upload%{linkEnd} file to attach'),
    },
    uploadMultipleMessage: {
      type: String,
      required: false,
      default: __('Drop or %{linkStart}upload%{linkEnd} files to attach'),
    },
    dropToStartMessage: {
      type: String,
      required: false,
      default: __('Drop your files to start your upload.'),
    },
    isFileValid: {
      type: Function,
      required: false,
      default: isValidImage,
    },
    validFileMimetypes: {
      type: Array,
      required: false,
      default: () => [VALID_IMAGE_FILE_MIMETYPE.mimetype],
    },
    singleFileSelection: {
      type: Boolean,
      required: false,
      default: false,
    },
    inputFieldName: {
      type: String,
      required: false,
      default: 'upload_file',
    },
    shouldUpdateInputOnFileDrop: {
      type: Boolean,
      required: false,
      default: false,
    },
    showUploadDesignOverlay: {
      type: Boolean,
      required: false,
      default: false,
    },
    uploadDesignOverlayText: {
      type: String,
      required: false,
      default: '',
    },
    validateDesignUploadOnDragover: {
      type: Boolean,
      required: false,
      default: false,
    },
    acceptDesignFormats: {
      type: String,
      required: false,
      default: '',
    },
    hideUploadTextOnDragging: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dragCounter: 0,
      isDragDataValid: true,
      animateUploadIcon: false,
    };
  },
  computed: {
    dragging() {
      return this.dragCounter !== 0;
    },
    iconStyles() {
      return {
        class: this.displayAsCard ? 'gl-mb-3' : 'gl-mr-3',
      };
    },
    validMimeTypeString() {
      return this.validFileMimetypes.join();
    },
    showDropzoneOverlay() {
      if (this.validateDesignUploadOnDragover && this.acceptDesignFormats) {
        return this.dragging && this.isDragDataValid && !this.enableDragBehavior;
      }
      return this.dragging && !this.enableDragBehavior;
    },
  },
  methods: {
    isValidUpload(files) {
      return files.every(this.isFileValid);
    },
    isValidDragDataType({ dataTransfer }) {
      return Boolean(
        dataTransfer && dataTransfer.types.some((t) => t === VALID_DATA_TRANSFER_TYPE),
      );
    },
    ondrop({ dataTransfer = {} }) {
      this.dragCounter = 0;
      // User already had feedback when dropzone was active, so bail here
      if (!this.isDragDataValid) {
        return;
      }

      const { files } = dataTransfer;
      if (!this.isValidUpload(Array.from(files))) {
        this.$emit('error');
        return;
      }

      // NOTE: This is a temporary solution to integrate dropzone into a Rails
      // form. On file drop if `shouldUpdateInputOnFileDrop` is true, the file
      // input value is updated. So that when the form is submitted — the file
      // value would be send together with the form data. This solution should
      // be removed when License file upload page is fully migrated:
      // https://gitlab.com/gitlab-org/gitlab/-/issues/352501
      // NOTE: as per https://caniuse.com/mdn-api_htmlinputelement_files, IE11
      // is not able to set input.files property, thought the user would still
      // be able to use the file picker dialogue option, by clicking the
      // "openFileUpload" button
      if (this.shouldUpdateInputOnFileDrop) {
        // Since FileList cannot be easily manipulated, to match requirement of
        // singleFileSelection, we're throwing an error if multiple files were
        // dropped on the dropzone
        // NOTE: we can drop this logic together with
        // `shouldUpdateInputOnFileDrop` flag
        if (this.singleFileSelection && files.length > 1) {
          this.$emit('error');
          return;
        }

        this.$refs.fileUpload.files = files;
      }

      this.$emit('change', this.singleFileSelection ? files[0] : files);
    },
    ondragenter(e) {
      this.$emit('dragenter', e);
      this.dragCounter += 1;
      this.isDragDataValid = this.isValidDragDataType(e);
    },
    ondragover({ dataTransfer }) {
      if (this.validateDesignUploadOnDragover) {
        this.isDragDataValid = Array.from(dataTransfer.items).some((item) =>
          this.acceptDesignFormats.includes(item.type),
        );
      }
    },
    ondragleave(e) {
      this.$emit('dragleave', e);
      this.dragCounter -= 1;
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    onFileInputChange(e) {
      this.$emit('change', this.singleFileSelection ? e.target.files[0] : e.target.files);
    },
    onMouseEnter() {
      this.animateUploadIcon = true;
    },
    onMouseLeave() {
      this.animateUploadIcon = false;
    },
  },
};
</script>

<template>
  <div
    class="gl-w-full"
    :class="{ 'gl-relative': !showUploadDesignOverlay }"
    @dragstart.prevent.stop
    @dragend.prevent.stop
    @dragover.prevent.stop="ondragover"
    @dragenter.prevent.stop="ondragenter"
    @dragleave.prevent.stop="ondragleave"
    @drop.prevent.stop="ondrop"
  >
    <slot>
      <button
        class="card upload-dropzone-card upload-dropzone-border gl-mb-0 gl-h-full gl-w-full gl-items-center gl-justify-center gl-px-5 gl-py-4"
        type="button"
        @click="openFileUpload"
        @mouseenter="onMouseEnter"
        @mouseleave="onMouseLeave"
      >
        <div
          :class="{ 'gl-flex-col': displayAsCard }"
          class="gl-flex gl-items-center gl-justify-center gl-text-center"
          data-testid="dropzone-area"
        >
          <gl-animated-upload-icon
            :is-on="animateUploadIcon || hideUploadTextOnDragging"
            :class="iconStyles.class"
          />
          <p
            v-if="!hideUploadTextOnDragging || !dragging"
            class="gl-mb-0"
            data-testid="upload-text"
          >
            <slot name="upload-text" :open-file-upload="openFileUpload">
              <gl-sprintf
                :message="singleFileSelection ? uploadSingleMessage : uploadMultipleMessage"
              >
                <template #link="{ content }">
                  <gl-link @click.stop="openFileUpload">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </slot>
          </p>
          <span v-if="hideUploadTextOnDragging && dragging">
            {{ s__('DesignManagement|Drop your images to start the upload.') }}
          </span>
        </div>
      </button>

      <input
        ref="fileUpload"
        type="file"
        :name="inputFieldName"
        :accept="validFileMimetypes"
        class="hide"
        :multiple="!singleFileSelection"
        @change="onFileInputChange"
      />
    </slot>
    <transition name="upload-dropzone-fade">
      <div
        v-show="showDropzoneOverlay"
        class="card gl-absolute gl-flex gl-h-full gl-w-full gl-items-center gl-justify-center gl-p-4"
        :class="{
          'design-upload-dropzone-overlay gl-z-200 gl-border-1 gl-border-dashed gl-border-blue-500':
            showUploadDesignOverlay && isDragDataValid,
          'upload-dropzone-overlay upload-dropzone-border': !showUploadDesignOverlay,
        }"
      >
        <!-- Design Upload Overlay Style for Work Items -->
        <template v-if="showUploadDesignOverlay">
          <div
            v-if="isDragDataValid && !hideUploadTextOnDragging"
            class="gl-absolute gl-bottom-6 gl-flex gl-items-center gl-rounded-base gl-bg-blue-950 gl-px-3 gl-py-2 gl-text-white"
            data-testid="design-upload-overlay"
          >
            <gl-animated-upload-icon :is-on="true" name="upload" />
            <span class="gl-ml-2">{{ uploadDesignOverlayText }}</span>
          </div>
        </template>
        <!-- Design Upload Overlay Style for Legacy Issues -->
        <template v-else>
          <div v-if="isDragDataValid" class="gl-max-w-1/2 gl-text-center">
            <slot name="valid-drag-data-slot">
              <h3 :class="{ 'gl-inline gl-text-base': !displayAsCard }">
                {{ __('Incoming!') }}
              </h3>
              <span>{{ dropToStartMessage }}</span>
            </slot>
          </div>
          <div v-else class="gl-max-w-1/2 gl-text-center">
            <slot name="invalid-drag-data-slot">
              <h3 :class="{ 'gl-inline gl-text-base': !displayAsCard }">
                {{ __('Oh no!') }}
              </h3>
              <span>{{
                __(
                  'You are trying to upload something other than an image. Please upload a .png, .jpg, .jpeg, .gif, .bmp, .tiff or .ico.',
                )
              }}</span>
            </slot>
          </div>
        </template>
      </div>
    </transition>
  </div>
</template>
