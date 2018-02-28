<script>
import TimeAgoMixin from '../../vue_shared/mixins/timeago';

const RepoFile = {
  mixins: [TimeAgoMixin],
  props: {
    file: {
      type: Object,
      required: true,
    },
    isMini: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Object,
      required: false,
      default() { return { tree: false }; },
    },
    hasFiles: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeFile: {
      type: Object,
      required: true,
    },
  },

  computed: {
    canShowFile() {
      return !this.loading.tree || this.hasFiles;
    },

    fileIcon() {
      const classObj = {
        'fa-spinner fa-spin': this.file.loading,
        [this.file.icon]: !this.file.loading,
      };
      return classObj;
    },

    fileIndentation() {
      return {
        'margin-left': `${this.file.level * 10}px`,
      };
    },

    activeFileClass() {
      return {
        active: this.activeFile.url === this.file.url,
      };
    },
  },

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    },
  },
};

export default RepoFile;
</script>

<template>
<tr
  v-if="canShowFile"
  class="file"
  :class="activeFileClass"
  @click.prevent="linkClicked(file)">
  <td>
    <i
      class="fa fa-fw file-icon"
      :class="fileIcon"
      :style="fileIndentation"
      aria-label="file icon">
    </i>
    <a
      :href="file.url"
      class="repo-file-name"
      :title="file.url">
      {{file.name}}
    </a>
  </td>

  <template v-if="!isMini">
    <td class="hidden-sm hidden-xs">
      <div class="commit-message">
        <a @click.stop :href="file.lastCommitUrl">
          {{file.lastCommitMessage}}
        </a>
      </div>
    </td>

    <td class="hidden-xs">
      <span
        class="commit-update"
        :title="tooltipTitle(file.lastCommitUpdate)">
        {{timeFormated(file.lastCommitUpdate)}}
      </span>
    </td>
  </template>
</tr>
</template>
