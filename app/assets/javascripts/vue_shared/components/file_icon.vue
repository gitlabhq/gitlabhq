<script>
  import getIconForFile from './file_icon/file_icon_map';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import icon from '../../vue_shared/components/icon.vue';

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
      loadingIcon,
      icon,
    },
    props: {
      fileName: {
        type: String,
        required: true,
      },

      folder: {
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
      spriteHref() {
        const iconName = getIconForFile(this.fileName) || 'file';
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
    <svg
      :class="[iconSizeClass, cssClasses]"
      v-if="!loading && !folder"
    >
      <use v-bind="{ 'xlink:href':spriteHref }" />
    </svg>
    <icon
      v-if="!loading && folder"
      :name="folderIconName"
      :size="size"
    />
    <loading-icon
      v-if="loading"
      :inline="true"
    />
  </span>
</template>
