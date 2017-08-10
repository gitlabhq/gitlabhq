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
      let classObj = {
        'fa-spinner' : this.file.loading,
        'fa-spin' : this.file.loading,
        [this.file.icon] : !this.file.loading,
      };
      return classObj;
    }
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
<tr class="file" v-if="canShowFile" :class="{'active': activeFile.url === file.url}" @click.prevent="linkClicked(file)">
  <td>
    <i class="fa fa-fw" :class="fileIcon" :style="{'margin-left': file.level * 10 + 'px'}"></i>
    <a :href="file.url" class="repo-file-name" :title="file.url">{{file.name}}</a>
  </td>

  <td v-if="!isMini" class="hidden-sm hidden-xs">
    <div class="commit-message">
      <a :href="file.lastCommitUrl">{{file.lastCommitMessage}}</a>
    </div>
  </td>

  <td v-if="!isMini" class="hidden-xs">
    <span class="commit-update" :title="tooltipTitle(file.lastCommitUpdate)">{{timeFormated(file.lastCommitUpdate)}}</span>
  </td>
</tr>
</template>
