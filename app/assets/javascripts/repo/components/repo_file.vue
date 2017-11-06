<script>
  import { mapActions, mapGetters } from 'vuex';
  import timeAgoMixin from '../../vue_shared/mixins/timeago';

  export default {
    mixins: [
      timeAgoMixin,
    ],
    props: {
      file: {
        type: Object,
        required: true,
      },
    },
    computed: {
      ...mapGetters([
        'isCollapsed',
      ]),
      fileIcon() {
        return {
          'fa-spinner fa-spin': this.file.loading,
          [this.file.icon]: !this.file.loading,
          'fa-folder-open': !this.file.loading && this.file.opened,
        };
      },
      levelIndentation() {
        return {
          marginLeft: `${this.file.level * 16}px`,
        };
      },
      shortId() {
        return this.file.id.substr(0, 8);
      },
    },
    methods: {
      ...mapActions([
        'clickedTreeRow',
      ]),
    },
  };
</script>

<template>
  <tr
    class="file"
    @click.prevent="clickedTreeRow(file)">
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
      <template v-if="file.type === 'submodule' && file.id">
        @
        <span class="commit-sha">
          <a
            @click.stop
            :href="file.tree_url"
          >
            {{ shortId }}
          </a>
        </span>
      </template>
    </td>

    <template v-if="!isCollapsed">
      <td class="hidden-sm hidden-xs">
        <a
          @click.stop
          :href="file.lastCommit.url"
          class="commit-message"
        >
          {{ file.lastCommit.message }}
        </a>
      </td>

      <td class="commit-update hidden-xs text-right">
        <span
          v-if="file.lastCommit.updatedAt"
          :title="tooltipTitle(file.lastCommit.updatedAt)"
        >
          {{ timeFormated(file.lastCommit.updatedAt) }}
        </span>
      </td>
    </template>
  </tr>
</template>
