<script>
import { uniqueId } from 'lodash-es';
import { GlButton, GlAvatar, GlSprintf, GlTruncate } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

const MAXIMUM_FILE_SIZE = 200 * 1024; // 200 KiB in bytes
const ALLOWED_FILE_EXTENSIONS = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'tiff', 'ico', 'webp'];
const ALLOWED_MIME_TYPES = [
  'image/png',
  'image/jpeg',
  'image/gif',
  'image/bmp',
  'image/tiff',
  'image/vnd.microsoft.icon',
  'image/webp',
];

export default {
  name: 'AvatarUploadDropzone',
  i18n: {
    uploadText: __('Drop or %{linkStart}upload%{linkEnd} an avatar.'),
    maxFileSize: s__('Profiles|The maximum file size allowed is 200 KiB.'),
    imageDimensions: s__('Profiles|The ideal image size is 192 x 192 pixels.'),
    removeAvatar: __('Remove avatar'),
    fileTooLarge: s__('Profiles|The file is too large. The maximum file size allowed is 200 KiB.'),
    invalidFileType: s__(
      'Profiles|The file format is not supported. Please try one of the following formats: %{formats}',
    ),
    uploadFailed: s__('Profiles|Failed to upload avatar. Please try again.'),
  },
  AVATAR_SHAPE_OPTION_RECT,
  // Validation (including the error message) is owned by this component in
  // `handleFileChange`, so UploadDropzone's internal validation is bypassed.
  acceptAnyFile: () => true,
  components: { GlButton, GlAvatar, GlSprintf, GlTruncate, UploadDropzone },
  props: {
    entity: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    value: {
      type: [String, File],
      required: false,
      default: '',
    },
    label: {
      type: String,
      required: true,
    },
    inputFieldName: {
      type: String,
      required: false,
      default: 'upload_file',
    },
    // Whether the persisted avatar (a `String` value) can be removed. A
    // locally selected `File` can always be discarded regardless of this
    // prop. Used e.g. for projects whose avatar comes from a `logo` file
    // committed to the repository, which cannot be removed from here.
    canRemove: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  emits: ['input'],
  data() {
    return {
      avatarObjectUrl: null,
      uploadError: null,
      inputId: uniqueId('avatar-upload-dropzone-input-'),
    };
  },
  computed: {
    avatarSrc() {
      if (this.avatarObjectUrl) {
        return this.avatarObjectUrl;
      }

      if (this.isValueAFile) {
        return null;
      }

      return this.value;
    },
    isValueAFile() {
      return this.value instanceof File;
    },
    showRemoveButton() {
      // A locally selected file can always be discarded; a persisted avatar
      // only when `canRemove` allows it.
      return Boolean(this.value) && (this.isValueAFile || this.canRemove);
    },
    showDropzone() {
      return !this.value || !this.showRemoveButton;
    },
    hasUploadError() {
      return Boolean(this.uploadError);
    },
    invalidFileTypeMessage() {
      return sprintf(this.$options.i18n.invalidFileType, {
        formats: ALLOWED_FILE_EXTENSIONS.join(', '),
      });
    },
  },
  watch: {
    value(newValue) {
      this.revokeAvatarObjectUrl();

      if (newValue instanceof File) {
        this.avatarObjectUrl = URL.createObjectURL(newValue);
      } else {
        this.avatarObjectUrl = null;
      }

      if (!(newValue instanceof File)) {
        // The native input should only hold a file while one is staged. Clear
        // it when the selection is discarded or replaced by a persisted URL,
        // so a stale file is never submitted with a surrounding form.
        this.$refs.dropzone?.clearInputFiles?.();
      }
    },
  },
  beforeDestroy() {
    this.revokeAvatarObjectUrl();
  },
  methods: {
    revokeAvatarObjectUrl() {
      if (this.avatarObjectUrl === null) {
        return;
      }

      URL.revokeObjectURL(this.avatarObjectUrl);
    },
    // Pure: returns the validation error message for the file, or `null`
    // when the file is a valid avatar.
    avatarValidationError(file) {
      if (file.size > MAXIMUM_FILE_SIZE) {
        return this.$options.i18n.fileTooLarge;
      }

      if (!ALLOWED_MIME_TYPES.includes(file.type)) {
        // Check file extension as fallback
        const extension = file.name.split('.').pop()?.toLowerCase();
        if (!extension || !ALLOWED_FILE_EXTENSIONS.includes(extension)) {
          return this.invalidFileTypeMessage;
        }
      }

      return null;
    },
    handleFileChange(file) {
      if (!file) {
        return;
      }

      this.uploadError = this.avatarValidationError(file);

      if (this.uploadError) {
        this.discardRejectedSelection();
        return;
      }

      this.$emit('input', file);
    },
    handleUploadError() {
      // Reached only for failures UploadDropzone reports without a file,
      // e.g. dropping multiple files with single-file selection.
      this.uploadError = this.$options.i18n.uploadFailed;
      this.discardRejectedSelection();
    },
    discardRejectedSelection() {
      // Remove the rejected file from the native input so it is not submitted
      // with a surrounding form.
      this.$refs.dropzone?.clearInputFiles?.();

      if (this.isValueAFile) {
        // A failed re-selection replaced the staged file in the native input,
        // so discard the staged file too. Otherwise the UI would keep showing
        // a staged file that would no longer be submitted with the form.
        this.$emit('input', null);
      }
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-flex gl-gap-x-5">
      <gl-avatar
        :entity-id="entity.id || null"
        :entity-name="entity.name || 'organization'"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :size="96"
        :src="avatarSrc"
      />
      <div class="gl-min-w-0">
        <label :for="inputId" class="gl-mb-3 gl-block gl-font-bold gl-leading-1">
          {{ label }}
        </label>
        <div v-if="showRemoveButton" class="gl-flex gl-items-center gl-gap-x-3">
          <gl-button @click="$emit('input', null)">{{ $options.i18n.removeAvatar }}</gl-button>
          <gl-truncate
            v-if="isValueAFile"
            class="gl-min-w-0 gl-max-w-48 gl-text-subtle"
            position="middle"
            :text="value.name"
          />
        </div>
        <upload-dropzone
          v-show="showDropzone"
          ref="dropzone"
          single-file-selection
          should-update-input-on-file-drop
          :is-file-valid="$options.acceptAnyFile"
          :has-upload-error="hasUploadError"
          :input-field-name="inputFieldName"
          :input-field-id="inputId"
          @change="handleFileChange"
          @error="handleUploadError"
        >
          <template #upload-text>
            <gl-sprintf :message="$options.i18n.uploadText">
              <template #link="{ content }">
                <span class="gl-link hover:gl-underline">{{ content }}</span>
              </template>
            </gl-sprintf>
          </template>
        </upload-dropzone>
        <p class="gl-mb-0 gl-mt-3 gl-text-subtle">
          {{ $options.i18n.imageDimensions }}
          {{ $options.i18n.maxFileSize }}
        </p>
        <p v-if="uploadError" class="gl-text-danger" role="alert" aria-live="assertive">
          {{ uploadError }}
        </p>
      </div>
    </div>
  </div>
</template>
