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
      isSubmodule() {
        return this.file.type === 'submodule';
      },
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
      submoduleColSpan() {
        return !this.isCollapsed && this.isSubmodule ? 3 : undefined;
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
    <td :colspan="submoduleColSpan">
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
      <template v-if="isSubmodule && file.id">
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

    <template v-if="!isCollapsed && !isSubmodule">
      <td class="hidden-sm hidden-xs">
        <a
          v-if="file.lastCommit.message"
          @click.stop
          :href="file.lastCommit.url"
          class="commit-message"
        >
          {{ file.lastCommit.message }}
        </a>
        <div
          v-else
          class="animation-container animation-container-small"
        >
          <div
            v-for="n in 6"
            :key="n"
            :class="'skeleton-line-' + n"
          >
          </div>
        </div>
      </td>

      <td class="commit-update hidden-xs text-right">
        <span
          v-if="file.lastCommit.updatedAt"
          :title="tooltipTitle(file.lastCommit.updatedAt)"
        >
          {{ timeFormated(file.lastCommit.updatedAt) }}
        </span>
        <div
          v-else
          class="animation-container animation-container-small animation-container-right"
        >
          <div
            v-for="n in 6"
            :key="n"
            :class="'skeleton-line-' + n"
          >
          </div>
        </div>
      </td>
    </template>
  </tr>
</template>
