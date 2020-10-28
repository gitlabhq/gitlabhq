<script>
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import createFlash from '~/flash';
import uploadDesignMutation from '../../graphql/mutations/upload_design.mutation.graphql';
import { UPLOAD_DESIGN_INVALID_FILETYPE_ERROR } from '../../utils/error_messages';
import { isValidDesignFile } from '../../utils/design_management_utils';
import { VALID_DATA_TRANSFER_TYPE, VALID_DESIGN_FILE_MIMETYPE } from '../../constants';

export default {
  components: {
    GlIcon,
    GlLink,
    GlSprintf,
  },
  props: {
    hasDesigns: {
      type: Boolean,
      required: true,
    },
    isDraggingDesign: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      dragCounter: 0,
      isDragDataValid: false,
    };
  },
  computed: {
    dragging() {
      return this.dragCounter !== 0;
    },
    iconStyles() {
      return {
        size: this.hasDesigns ? 24 : 16,
        class: this.hasDesigns ? 'gl-mb-2' : 'gl-mr-3 gl-text-gray-500',
      };
    },
  },
  methods: {
    isValidUpload(files) {
      return files.every(isValidDesignFile);
    },
    isValidDragDataType({ dataTransfer }) {
      return Boolean(dataTransfer && dataTransfer.types.some(t => t === VALID_DATA_TRANSFER_TYPE));
    },
    ondrop({ dataTransfer = {} }) {
      this.dragCounter = 0;
      // User already had feedback when dropzone was active, so bail here
      if (!this.isDragDataValid) {
        return;
      }

      const { files } = dataTransfer;
      if (!this.isValidUpload(Array.from(files))) {
        createFlash({ message: UPLOAD_DESIGN_INVALID_FILETYPE_ERROR });
        return;
      }

      this.$emit('change', files);
    },
    ondragenter(e) {
      this.dragCounter += 1;
      this.isDragDataValid = this.isValidDragDataType(e);
    },
    ondragleave() {
      this.dragCounter -= 1;
    },
    openFileUpload() {
      this.$refs.fileUpload.click();
    },
    onDesignInputChange(e) {
      this.$emit('change', e.target.files);
    },
  },
  uploadDesignMutation,
  VALID_DESIGN_FILE_MIMETYPE,
};
</script>

<template>
  <div
    class="gl-w-full gl-relative"
    @dragstart.prevent.stop
    @dragend.prevent.stop
    @dragover.prevent.stop
    @dragenter.prevent.stop="ondragenter"
    @dragleave.prevent.stop="ondragleave"
    @drop.prevent.stop="ondrop"
  >
    <slot>
      <button
        class="card design-dropzone-card design-dropzone-border gl-w-full gl-h-full gl-align-items-center gl-justify-content-center gl-p-3"
        @click="openFileUpload"
      >
        <div
          :class="{ 'gl-flex-direction-column': hasDesigns }"
          class="gl-display-flex gl-align-items-center gl-justify-content-center gl-text-center"
          data-testid="dropzone-area"
        >
          <gl-icon name="upload" :size="iconStyles.size" :class="iconStyles.class" />
          <p class="gl-mb-0">
            <gl-sprintf :message="__('Drop or %{linkStart}upload%{linkEnd} designs to attach')">
              <template #link="{ content }">
                <gl-link @click.stop="openFileUpload">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </p>
        </div>
      </button>

      <input
        ref="fileUpload"
        type="file"
        name="design_file"
        :accept="$options.VALID_DESIGN_FILE_MIMETYPE.mimetype"
        class="hide"
        multiple
        @change="onDesignInputChange"
      />
    </slot>
    <transition name="design-dropzone-fade">
      <div
        v-show="dragging && !isDraggingDesign"
        class="card design-dropzone-border design-dropzone-overlay gl-w-full gl-h-full gl-absolute gl-display-flex gl-align-items-center gl-justify-content-center gl-p-3 gl-bg-white"
      >
        <div v-show="!isDragDataValid" class="mw-50 gl-text-center">
          <h3 :class="{ 'gl-font-base gl-display-inline': !hasDesigns }">{{ __('Oh no!') }}</h3>
          <span>{{
            __(
              'You are trying to upload something other than an image. Please upload a .png, .jpg, .jpeg, .gif, .bmp, .tiff or .ico.',
            )
          }}</span>
        </div>
        <div v-show="isDragDataValid" class="mw-50 gl-text-center">
          <h3 :class="{ 'gl-font-base gl-display-inline': !hasDesigns }">{{ __('Incoming!') }}</h3>
          <span>{{ __('Drop your designs to start your upload.') }}</span>
        </div>
      </div>
    </transition>
  </div>
</template>
