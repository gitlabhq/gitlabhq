<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import { createItemVisibilityObserver, observeElementsByIds } from '~/lib/utils/lazy_render_utils';
import getRefMixin from '../../mixins/get_ref';
import projectPathQuery from '../../queries/project_path.query.graphql';
import TableHeader from './header.vue';
import ParentRow from './parent_row.vue';
import TableRow from './row.vue';
import SkeletonLoader from './skeleton_loader.vue';

export default {
  components: {
    SkeletonLoader,
    TableHeader,
    TableRow,
    ParentRow,
    GlButton,
  },
  mixins: [getRefMixin],
  props: {
    commits: {
      type: Array,
      required: false,
      default: () => [],
    },
    path: {
      type: String,
      required: true,
    },
    entries: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    loadingPath: {
      type: String,
      required: false,
      default: '',
    },
    hasMore: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['showMore'],
  apollo: {
    projectPath: {
      query: projectPathQuery,
    },
  },
  data() {
    return {
      projectPath: '',
      rowNumbers: {},
      isProcessingShowMore: false,
      appearedItems: {},
      itemObserver: null,
    };
  },
  computed: {
    totalEntries() {
      return Object.values(this.entries).flat().length;
    },
    tableCaption() {
      if (this.isLoading) {
        return sprintf(
          __(
            'Loading files, directories, and submodules in the path %{path} for commit reference %{ref}',
          ),
          { path: this.path, ref: this.ref },
        );
      }

      return sprintf(
        __('Files, directories, and submodules in the path %{path} for commit reference %{ref}'),
        { path: this.path, ref: this.ref },
      );
    },
    showParentRow() {
      return ['', '/'].indexOf(this.path) === -1;
    },
    commitMap() {
      return new Map(this.commits.map((c) => [c.filePath, c]));
    },
  },
  watch: {
    totalEntries(newCount, oldCount) {
      if (newCount > oldCount) {
        this.$nextTick(() =>
          observeElementsByIds(this.$el, this.itemObserver, this.syncAppearedItems()),
        );
      }
    },
  },
  mounted() {
    this.itemObserver = createItemVisibilityObserver(
      (itemId) => {
        // Direct property mutation works here because syncAppearedItems() pre-initializes
        // all keys with false, so Vue 2 has already made them reactive.
        if (itemId && itemId in this.appearedItems) this.appearedItems[itemId] = true;
      },
      { once: true, rootElement: document.querySelector('.js-static-panel-inner') },
    );
    this.$nextTick(() =>
      observeElementsByIds(this.$el, this.itemObserver, this.syncAppearedItems()),
    );
  },
  beforeDestroy() {
    this.itemObserver?.disconnect();
  },
  methods: {
    syncAppearedItems() {
      const newIds = Object.values(this.entries)
        .flatMap((group) => group.map((entry, index) => [this.itemId(entry, index), false]))
        .filter(([id]) => !(id in this.appearedItems));
      if (newIds.length)
        this.appearedItems = { ...this.appearedItems, ...Object.fromEntries(newIds) };
      return newIds.map(([id]) => id);
    },
    itemId(entry, index) {
      return `${entry.flatPath}-${entry.id}-${index}`;
    },
    showMore() {
      this.isProcessingShowMore = true;
      // Defer heavy rendering to improve INP (Interaction to Next Paint)
      // This allows the browser to paint the button interaction immediately
      // before processing the new entries. See: https://web.dev/articles/optimize-inp
      setTimeout(() => {
        this.$emit('showMore');
        this.isProcessingShowMore = false;
      }, 0);
    },
    generateRowNumber(entry, index) {
      const { flatPath, id } = entry;
      const key = `${flatPath}-${id}-${index}`;

      // We adjust the offset that we request based on the type of entry

      const numTrees = this.entries?.trees?.length || 0;
      const numBlobs = this.entries?.blobs?.length || 0;
      if (!this.rowNumbers[key] && this.rowNumbers[key] !== 0) {
        if (entry.type === 'commit') {
          // submodules are rendered before blobs but are in the last pages the api response
          this.rowNumbers[key] = numTrees + numBlobs + index;
        } else if (entry.type === 'blob') {
          this.rowNumbers[key] = numTrees + index;
        } else {
          this.rowNumbers[key] = index;
        }
      }

      return this.rowNumbers[key];
    },
    getCommit(fileName) {
      return this.commitMap.get(joinPaths(this.path, fileName));
    },
  },
};
</script>

<template>
  <div class="tree-content-holder">
    <div class="table-holder gl-border gl-rounded-lg gl-border-section">
      <table
        :aria-label="tableCaption"
        class="table tree-table"
        :class="{ 'gl-table-fixed': !showParentRow }"
        aria-live="polite"
        data-testid="file-tree-table"
      >
        <table-header v-once />
        <tbody>
          <parent-row
            v-if="showParentRow"
            :commit-ref="escapedRef"
            :path="path"
            :loading-path="loadingPath"
          />
          <template v-for="val in entries">
            <template v-for="(entry, index) in val">
              <table-row
                v-if="appearedItems[itemId(entry, index)]"
                :id="entry.id"
                :key="`${itemId(entry, index)}-row`"
                :data-item-id="itemId(entry, index)"
                :sha="entry.sha"
                :project-path="projectPath"
                :current-path="path"
                :name="entry.name"
                :path="entry.flatPath"
                :type="entry.type"
                :url="entry.webUrl || entry.webPath"
                :mode="entry.mode"
                :submodule-tree-url="entry.treeUrl"
                :lfs-oid="entry.lfsOid"
                :loading-path="loadingPath"
                :total-entries="totalEntries"
                :row-number="generateRowNumber(entry, index)"
                :commit-info="getCommit(entry.name)"
                v-on="$listeners"
              />
              <tr
                v-else
                :key="`${itemId(entry, index)}-placeholder`"
                :data-item-id="itemId(entry, index)"
                class="tree-item"
                aria-hidden="true"
              >
                <td class="tree-item-file-name gl-text-transparent">{{ entry.name }}</td>
                <td class="gl-hidden @sm/panel:gl-table-cell"></td>
                <td></td>
              </tr>
            </template>
          </template>
          <template v-if="isLoading">
            <tr v-for="i in 3" :key="i" aria-hidden="true" data-testid="loader">
              <td><skeleton-loader /></td>
              <td class="gl-hidden @sm/panel:gl-block">
                <skeleton-loader />
              </td>
              <td>
                <div class="gl-flex @lg/panel:gl-justify-end">
                  <skeleton-loader />
                </div>
              </td>
            </tr>
          </template>
          <template v-if="hasMore">
            <tr>
              <td align="center" colspan="3">
                <gl-button
                  size="small"
                  :loading="isProcessingShowMore || isLoading"
                  @click="showMore"
                >
                  {{ s__('ProjectFileTree|Show more') }}
                </gl-button>
              </td>
            </tr>
          </template>
        </tbody>
      </table>
    </div>
  </div>
</template>
