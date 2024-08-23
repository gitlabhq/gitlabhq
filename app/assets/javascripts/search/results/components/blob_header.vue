<script>
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { s__ } from '~/locale';

export default {
  name: 'BlobHeader',
  components: {
    FileIcon,
    ClipboardButton,
  },
  props: {
    filePath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    fileUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  i18n: {
    fileLink: s__('GlobalSearch|Open file in repository'),
  },
  computed: {
    gfmCopyText() {
      return `\`${this.filePath}\``;
    },
  },
};
</script>
<template>
  <div class="file-header-content gl-flex gl-items-center gl-leading-1">
    <file-icon :file-name="filePath" :size="16" aria-hidden="true" css-classes="gl-mr-3" />

    <a :href="fileUrl" :title="$options.i18n.fileLink">
      <template v-if="projectPath">
        <strong class="project-path-content" data-testid="project-path-content"
          >{{ projectPath }}:
        </strong>
      </template>

      <strong class="file-name-content" data-testid="file-name-content">{{ filePath }}</strong>
    </a>
    <clipboard-button
      :text="filePath"
      :gfm="gfmCopyText"
      :title="__('Copy file path')"
      category="tertiary"
      css-class="gl-mr-2"
    />
  </div>
</template>
