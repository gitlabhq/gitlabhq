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
<tr v-if="!loading.tree || hasFiles" :class="{'active': activeFile.url === file.url}">
  <td>
    <i class="fa" :class="file.icon" :style="{'margin-left': file.level * 10 + 'px'}"></i>
    <a :href="file.url" @click.prevent="linkClicked(file)" class="repo-file-name" :title="file.url">{{file.name}}</a>
  </td>

  <td v-if="!isMini" class="hidden-sm hidden-xs">
    <div class="commit-message">{{file.lastCommitMessage}}</div>
  </td>

  <td v-if="!isMini" class="hidden-xs">
    <span>{{timeFormated(file.lastCommitUpdate)}}</span>
  </td>
</tr>
</template>
