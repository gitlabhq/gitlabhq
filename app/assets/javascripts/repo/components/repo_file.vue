<script>
  import { mapActions, mapGetters } from 'vuex';
  import timeAgoMixin from '../../vue_shared/mixins/timeago';
  import skeletonLoadingContainer from '../../vue_shared/components/skeleton_loading_container.vue';

  export default {
    mixins: [
      timeAgoMixin,
    ],
    components: {
      skeletonLoadingContainer,
    },
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
        return !this.isCollapsed && this.isSubmodule ? 3 : 1;
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
    <td
      class="multi-file-table-col-name"
      :colspan="submoduleColSpan"
    >
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
        <skeleton-loading-container
          v-else
          :small="true"
        />
      </td>

      <td class="commit-update hidden-xs text-right">
        <span
          v-if="file.lastCommit.updatedAt"
          :title="tooltipTitle(file.lastCommit.updatedAt)"
        >
          {{ timeFormated(file.lastCommit.updatedAt) }}
        </span>
        <skeleton-loading-container
          v-else
          class="animation-container-right"
          :small="true"
        />
      </td>
    </template>
  </tr>
</template>
