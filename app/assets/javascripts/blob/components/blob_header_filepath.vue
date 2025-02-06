<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import featureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    FileIcon,
    ClipboardButton,
    GlBadge,
    GlLink,
  },
  mixins: [featureFlagMixin()],
  props: {
    blob: {
      type: Object,
      required: true,
    },
    showPath: {
      type: Boolean,
      required: false,
      default: true,
    },
    showAsLink: {
      type: Boolean,
      required: false,
      default: false,
    },
    showBlobSize: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    blobSize() {
      return numberToHumanSize(this.blob.size);
    },
    gfmCopyText() {
      return `\`${this.blob.path}\``;
    },
    showLfsBadge() {
      return this.blob.storedExternally && this.blob.externalStorage === 'lfs';
    },
    fileName() {
      if (this.showPath) {
        return this.blob.path;
      }

      return this.blob.name;
    },
    linkHref() {
      return this.showAsLink ? { href: this.blob?.webPath } : {};
    },
  },
};
</script>
<template>
  <div class="file-header-content gl-flex gl-items-center gl-leading-1">
    <slot name="filepath-prepend"></slot>

    <template v-if="fileName">
      <file-icon :file-name="fileName" :size="16" aria-hidden="true" css-classes="gl-mr-3" />
      <component
        :is="showAsLink ? 'gl-link' : 'strong'"
        v-bind="linkHref"
        class="file-title-name js-blob-header-filepath gl-mr-1 gl-break-all gl-font-bold gl-text-strong"
        :class="{ '!gl-text-blue-700 hover:gl-cursor-pointer': showAsLink }"
        data-testid="file-title-content"
        >{{ fileName }}</component
      >
    </template>

    <clipboard-button
      v-if="!glFeatures.blobOverflowMenu"
      :text="blob.path"
      :gfm="gfmCopyText"
      :title="__('Copy file path')"
      category="tertiary"
      css-class="gl-mr-2"
    />

    <small v-if="showBlobSize" class="gl-mr-3 gl-text-subtle">{{ blobSize }}</small>

    <gl-badge v-if="showLfsBadge">{{ __('LFS') }}</gl-badge>
  </div>
</template>
