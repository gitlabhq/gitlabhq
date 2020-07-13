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
        createFlash(UPLOAD_DESIGN_INVALID_FILETYPE_ERROR);
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
    class="w-100 position-relative"
    @dragstart.prevent.stop
    @dragend.prevent.stop
    @dragover.prevent.stop
    @dragenter.prevent.stop="ondragenter"
    @dragleave.prevent.stop="ondragleave"
    @drop.prevent.stop="ondrop"
  >
    <slot>
      <button
        class="card design-dropzone-card design-dropzone-border w-100 h-100 gl-align-items-center gl-justify-content-center gl-p-3"
        @click="openFileUpload"
      >
        <div
          :class="{ 'gl-flex-direction-column': hasDesigns }"
          class="gl-display-flex gl-align-items-center gl-justify-content-center gl-text-center"
          data-testid="dropzone-area"
        >
          <gl-icon name="upload" :size="24" :class="hasDesigns ? 'gl-mb-2' : 'gl-mr-4'" />
          <gl-sprintf
            :message="
              __(
                '%{contentStart}Drop files to attach, or %{contentEnd}%{linkStart}browse%{linkEnd}',
              )
            "
          >
            <template #content="{ content }">
              <span class="gl-font-weight-bold">{{ content }}&nbsp;</span>
            </template>
            <template #link="{ content }">
              <gl-link @click.stop="openFileUpload">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
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
        v-show="dragging"
        class="card design-dropzone-border design-dropzone-overlay w-100 h-100 position-absolute d-flex-center p-3 bg-white"
      >
        <div v-show="!isDragDataValid" class="mw-50 text-center">
          <h3 :class="{ 'gl-font-base gl-display-inline': !hasDesigns }">{{ __('Oh no!') }}</h3>
          <span>{{
            __(
              'You are trying to upload something other than an image. Please upload a .png, .jpg, .jpeg, .gif, .bmp, .tiff or .ico.',
            )
          }}</span>
        </div>
        <div v-show="isDragDataValid" class="mw-50 text-center">
          <h3 :class="{ 'gl-font-base gl-display-inline': !hasDesigns }">{{ __('Incoming!') }}</h3>
          <span>{{ __('Drop your designs to start your upload.') }}</span>
        </div>
      </div>
    </transition>
  </div>
</template>
