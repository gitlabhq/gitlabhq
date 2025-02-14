<script>
import { getIconForFile } from '@gitlab/svgs/src/file_icon_map';
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { FILE_SYMLINK_MODE } from '../constants';

/* This is a re-usable vue component for rendering a svg sprite
    icon

    Sample configuration:

    <file-icon
      name="retry"
      :size="32"
      css-classes="top"
    />

  */
export default {
  components: {
    GlLoadingIcon,
    GlIcon,
  },
  props: {
    fileName: {
      type: String,
      required: true,
    },
    fileMode: {
      type: String,
      required: false,
      default: '',
    },
    folder: {
      type: Boolean,
      required: false,
      default: false,
    },
    submodule: {
      type: Boolean,
      required: false,
      default: false,
    },
    opened: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    size: {
      type: Number,
      required: false,
      default: 16,
    },
    cssClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isSymlink() {
      return this.fileMode === FILE_SYMLINK_MODE;
    },
    spriteHref() {
      const iconName = this.submodule ? 'folder-git' : getIconForFile(this.fileName) || 'file';

      return `${gon.sprite_file_icons}#${iconName}`;
    },
    folderIconName() {
      return this.opened ? 'folder-open' : 'folder';
    },
    iconSizeClass() {
      return this.size ? `s${this.size}` : '';
    },
  },
};
</script>
<template>
  <span>
    <gl-loading-icon v-if="loading" size="sm" :inline="true" />
    <gl-icon v-else-if="isSymlink" name="symlink" :size="size" />
    <svg v-else-if="!folder" :key="spriteHref" :class="[iconSizeClass, cssClasses]">
      <use :href="spriteHref" />
    </svg>
    <gl-icon v-else :name="folderIconName" :size="size" class="folder-icon" />
  </span>
</template>
