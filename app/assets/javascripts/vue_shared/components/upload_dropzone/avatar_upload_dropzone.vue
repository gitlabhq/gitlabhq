<script>
import { GlButton, GlAvatar, GlSprintf, GlTruncate } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  i18n: {
    uploadText: __('Drop or %{linkStart}upload%{linkEnd} an avatar.'),
    maxFileSize: s__('Profiles|The maximum file size allowed is 200KB.'),
    imageDimensions: s__('Profiles|The ideal image size is 192 x 192 pixels.'),
    removeAvatar: __('Remove avatar'),
  },
  AVATAR_SHAPE_OPTION_RECT,
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
  },
  data() {
    return {
      avatarObjectUrl: null,
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
  },
  watch: {
    value(newValue) {
      this.revokeAvatarObjectUrl();

      if (newValue instanceof File) {
        this.avatarObjectUrl = URL.createObjectURL(newValue);
      } else {
        this.avatarObjectUrl = null;
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
  },
};
</script>

<template>
  <div class="gl-display-flex gl-column-gap-5">
    <gl-avatar
      :entity-id="entity.id || null"
      :entity-name="entity.name || 'organization'"
      :shape="$options.AVATAR_SHAPE_OPTION_RECT"
      :size="96"
      :src="avatarSrc"
    />
    <div class="gl-min-w-0">
      <p class="gl-font-weight-bold gl-line-height-1 gl-mb-3">
        {{ label }}
      </p>
      <div v-if="value" class="gl-display-flex gl-align-items-center gl-column-gap-3">
        <gl-button @click="$emit('input', null)">{{ $options.i18n.removeAvatar }}</gl-button>
        <gl-truncate
          v-if="isValueAFile"
          class="gl-text-secondary gl-max-w-48 gl-min-w-0"
          position="middle"
          :text="value.name"
        />
      </div>
      <upload-dropzone v-else single-file-selection @change="$emit('input', $event)">
        <template #upload-text>
          <gl-sprintf :message="$options.i18n.uploadText">
            <template #link="{ content }">
              <span class="gl-link gl-hover-text-decoration-underline">{{ content }}</span>
            </template>
          </gl-sprintf>
        </template>
      </upload-dropzone>
      <p class="gl-mb-0 gl-mt-3 gl-text-secondary">
        {{ $options.i18n.imageDimensions }}
        {{ $options.i18n.maxFileSize }}
      </p>
    </div>
  </div>
</template>
