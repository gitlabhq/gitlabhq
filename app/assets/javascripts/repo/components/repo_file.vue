<script>
  import timeAgoMixin from '../../vue_shared/mixins/timeago';
  import eventHub from '../event_hub';
  import repoMixin from '../mixins/repo_mixin';

  export default {
    mixins: [
      repoMixin,
      timeAgoMixin,
    ],
    props: {
      file: {
        type: Object,
        required: true,
      },
    },
    computed: {
      fileIcon() {
        const classObj = {
          'fa-spinner fa-spin': this.file.loading,
          [this.file.icon]: !this.file.loading,
          'fa-folder-open': !this.file.loading && this.file.opened,
        };
        return classObj;
      },
      levelIndentation() {
        return {
          marginLeft: `${this.file.level * 16}px`,
        };
      },
    },
    methods: {
      linkClicked(file) {
        eventHub.$emit('linkclicked', file);
      },
    },
  };
</script>

<template>
  <tr
    class="file"
    @click.stop="linkClicked(file)">
    <td>
      <i
        class="fa fa-fw file-icon"
        :class="fileIcon"
        :style="levelIndentation"
        aria-hidden="true"
      >
      </i>
      <a
        :href="file.url"
        class="repo-file-name"
      >
        {{ file.name }}
      </a>
    </td>

    <template v-if="!isMini">
      <td class="hidden-sm hidden-xs">
        <a
          @click.stop
          :href="file.lastCommit.url"
        >
          {{ file.lastCommit.message }}
        </a>
      </td>

      <td class="hidden-xs text-right">
        <span :title="tooltipTitle(file.lastCommit.updatedAt)">
          {{ timeFormated(file.lastCommit.updatedAt) }}
        </span>
      </td>
    </template>
  </tr>
</template>
