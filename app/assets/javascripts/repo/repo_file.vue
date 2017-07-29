<script>
import TimeAgoMixin from '../vue_shared/mixins/timeago';

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

  methods: {
    linkClicked(file) {
      this.$emit('linkclicked', file);
    },
  },
};

export default RepoFile;
</script>

<template>
<tr class="file" v-if="!loading.tree || hasFiles" :class="{'active': activeFile.url === file.url}">
  <td @click.prevent="linkClicked(file)">
    <i class="fa" v-if="!file.loading" :class="file.icon" :style="{'margin-left': file.level * 10 + 'px'}"></i>
    <i class="fa fa-spinner fa-spin" v-if="file.loading" :style="{'margin-left': file.level * 10 + 'px'}"></i>
    <a :href="file.url" class="repo-file-name" :title="file.url">{{file.name}}</a>
  </td>

  <td v-if="!isMini" class="hidden-sm hidden-xs">
    <div class="commit-message">{{file.lastCommitMessage}}</div>
  </td>

  <td v-if="!isMini" class="hidden-xs">
    <span class="commit-update" :title="tooltipTitle(file.lastCommitUpdate)">{{timeFormated(file.lastCommitUpdate)}}</span>
  </td>
</tr>
</template>
