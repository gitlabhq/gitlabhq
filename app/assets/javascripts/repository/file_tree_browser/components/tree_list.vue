<script>
import { GlTooltipDirective, GlLoadingIcon, GlFormInput, GlIcon, GlTooltip } from '@gitlab/ui';
import micromatch from 'micromatch';
import { createAlert } from '~/alert';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileTreeBrowserToggle from '~/repository/file_tree_browser/components/file_tree_browser_toggle.vue';
import { s__, __ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { joinPaths } from '~/lib/utils/url_utility';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import { TREE_PAGE_SIZE } from '~/repository/constants';
import { getRefType } from '~/repository/utils/ref_type';
import { FOCUS_FILE_TREE_BROWSER_FILTER_BAR, keysFor } from '~/behaviors/shortcuts/keybindings';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { Mousetrap } from '~/lib/mousetrap';
import Shortcut from '~/behaviors/shortcuts/shortcut.vue';
import {
  normalizePath,
  dedupeByFlatPathAndId,
  generateShowMoreItem,
  directoryContainsChild,
  shouldStopPagination,
  hasMorePages,
  isExpandable,
  handleTreeKeydown,
} from '../utils';

export default {
  FOCUS_FILE_TREE_BROWSER_FILTER_BAR,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlFormInput,
    GlIcon,
    FileRow,
    GlLoadingIcon,
    FileTreeBrowserToggle,
    GlTooltip,
    Shortcut,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    currentRef: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    refType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      filter: '',
      directoriesCache: {},
      expandedPathsMap: {},
      loadingPathsMap: {},
      flatFilesList: [],
    };
  },
  computed: {
    isRootLoading() {
      return this.isDirectoryLoading('/');
    },
    filterSearchShortcutKey() {
      if (this.shortcutsDisabled) {
        return null;
      }
      return keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR)[0];
    },
    shortcutsDisabled() {
      return shouldDisableShortcuts();
    },
    filteredFlatFilesList() {
      const filter = this.filter.trim();
      if (!filter) return this.flatFilesList;

      const terms = filter
        .toLowerCase()
        .split(',')
        .map((s) => s.trim())
        .filter(Boolean);
      const pattern = terms.length > 1 ? `(${terms.join('|')})` : terms[0];

      return this.flatFilesList.filter((item) =>
        micromatch.contains(item.path || '', pattern, { nocase: true }),
      );
    },
    currentRouterPath() {
      return this.$route.params?.path && normalizePath(this.$route.params.path);
    },
    siblingMap() {
      const map = new Map();
      this.filteredFlatFilesList.forEach((item) => {
        const key = `${item.parentPath || ''}-${item.level}`;
        if (!map.has(key)) map.set(key, []);
        map.get(key).push(item.id);
      });
      return map;
    },
  },
  watch: {
    directoriesCache: { deep: true, handler: 'updateFlatFilesList' },
    expandedPathsMap: { deep: true, handler: 'updateFlatFilesList' },
  },
  mounted() {
    this.expandPathAncestors(this.currentRouterPath || '/');
    this.mousetrap = new Mousetrap();

    if (!this.shortcutsDisabled) {
      this.mousetrap.bind(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR), this.triggerFocusFilterBar);
    }
  },
  beforeDestroy() {
    this.mousetrap.unbind(keysFor(FOCUS_FILE_TREE_BROWSER_FILTER_BAR));
  },
  methods: {
    updateFlatFilesList() {
      if (this.isRootLoading) return;
      // Replace array contents in-place to maintain reactivity
      this.flatFilesList.splice(0, this.flatFilesList.length, ...this.buildList('/', 0));
    },
    isCurrentPath(path) {
      if (!this.$route.params.path) return path === '/';
      return path === this.currentRouterPath;
    },
    buildList(path, level) {
      const contents = this.getDirectoryContents(path);
      return this.processDirectories({ trees: contents.trees, path, level })
        .concat(this.processFiles({ blobs: contents.blobs, path, level }))
        .concat(this.processSubmodules({ submodules: contents.submodules, path, level }));
    },
    processDirectories({ trees = [], path, level }) {
      const directoryList = [];

      trees.forEach((tree, index) => {
        const treePath = normalizePath(tree.path || tree.name);
        directoryList.push({
          id: `${treePath}-${tree.id}-${index}`,
          path: treePath,
          routerPath: joinPaths('/-/tree', this.currentRef, treePath),
          type: 'tree',
          name: tree.name,
          level,
          opened: Boolean(this.expandedPathsMap[treePath]),
          loading: this.isDirectoryLoading(treePath),
        });

        if (this.shouldRenderShowMore(treePath, path))
          directoryList.push(generateShowMoreItem(tree.id, path, level));

        // Recursively add children for expanded directories
        if (this.expandedPathsMap[treePath] && !this.isDirectoryLoading(treePath)) {
          directoryList.push(...this.buildList(treePath, level + 1));
        }
      });

      return directoryList;
    },
    processFiles({ blobs = [], path, level }) {
      const filesList = [];

      blobs.forEach((blob, index) => {
        const blobPath = normalizePath(blob.path);
        filesList.push({
          id: `${blobPath}-${blob.id}-${index}`,
          fileHash: blob.sha,
          path: blobPath,
          routerPath: joinPaths('/-/blob', this.currentRef, blobPath),
          name: blob.name,
          mode: blob.mode,
          level,
        });

        if (this.shouldRenderShowMore(blobPath, path))
          filesList.push(generateShowMoreItem(blob.id, path, level));
      });

      return filesList;
    },
    processSubmodules({ submodules = [], path, level }) {
      const submodulesList = [];

      submodules.forEach((submodule, index) => {
        const submodulePath = normalizePath(submodule.path || submodule.name);
        submodulesList.push({
          id: `${submodulePath}-${submodule.id}-${index}`,
          fileHash: submodule.sha,
          path: submodulePath,
          name: submodule.name,
          submodule: true,
          level,
        });

        if (this.shouldRenderShowMore(submodulePath, path))
          submodulesList.push(generateShowMoreItem(submodule.id, path, level));
      });

      return submodulesList;
    },
    async fetchDirectory(dirPath) {
      const path = normalizePath(dirPath);
      const apiPath = path === '/' ? path : path.substring(1);
      const nextPageCursor = this.directoriesCache[path]?.pageInfo?.endCursor || '';

      if ((this.directoriesCache[path] && !nextPageCursor) || this.loadingPathsMap[path]) return;

      this.loadingPathsMap = { ...this.loadingPathsMap, [path]: true };

      try {
        const { projectPath, currentRef, refType } = this;
        const { data } = await this.$apollo.query({
          query: paginatedTreeQuery,
          variables: {
            projectPath,
            ref: currentRef,
            refType: getRefType(refType),
            path: apiPath,
            nextPageCursor,
            pageSize: TREE_PAGE_SIZE,
          },
        });

        const { project } = data;
        const treeData = project?.repository?.paginatedTree?.nodes[0];
        const directoryContents = {
          trees: dedupeByFlatPathAndId(treeData.trees.nodes),
          blobs: dedupeByFlatPathAndId(treeData.blobs.nodes),
          submodules: dedupeByFlatPathAndId(treeData.submodules.nodes),
        };
        const cached = this.directoriesCache[path] || { trees: [], blobs: [], submodules: [] };

        this.directoriesCache = {
          ...this.directoriesCache,
          [path]: {
            trees: [...cached.trees, ...directoryContents.trees],
            blobs: [...cached.blobs, ...directoryContents.blobs],
            submodules: [...cached.submodules, ...directoryContents.submodules],
            pageInfo: project?.repository?.paginatedTree?.pageInfo,
          },
        };
      } catch (error) {
        createAlert({
          message: __('Error fetching data. Please try again.'),
          captureError: true,
          error,
        });
      } finally {
        const newMap = { ...this.loadingPathsMap };
        delete newMap[path];
        this.loadingPathsMap = newMap;
      }
    },

    // Expand all parent directories leading to a path
    async expandPathAncestors(path) {
      await this.fetchDirectory('/');
      const segments = (path || '').split('/').filter(Boolean);
      if (!isExpandable(segments)) return;

      const expand = async (index = 0, currentPath = '', page = 0) => {
        if (index >= segments.length) return;

        const parent = currentPath || '/';
        const segment = segments[index];
        const parentContents = this.getDirectoryContents(parent);

        // Check if segment exists in parent directory
        if (!directoryContainsChild(parentContents, segment)) {
          if (shouldStopPagination(page, this.loadingPathsMap[parent])) return;

          await this.fetchDirectory(parent);

          // Check if found after fetch
          const updatedContents = this.getDirectoryContents(parent);
          if (!directoryContainsChild(updatedContents, segment)) {
            // If more pages exist, try next page
            if (hasMorePages(updatedContents)) {
              await expand(index, currentPath, page + 1);
              return;
            }
            return; // Not found
          }
        }

        // Expand and move to next segment
        const next = `${currentPath}/${segment}`;
        this.expandedPathsMap = { ...this.expandedPathsMap, [next]: true };
        if (!this.directoriesCache[next]) await this.fetchDirectory(next);
        await expand(index + 1, next);
      };

      await expand();
    },

    toggleDirectory(normalizedPath, { toggleClose = true } = {}) {
      if (!this.expandedPathsMap[normalizedPath]) {
        // If directory is collapsed, expand it
        this.expandedPathsMap = {
          ...this.expandedPathsMap,
          [normalizedPath]: true,
        };
        this.fetchDirectory(normalizedPath);
      } else if (toggleClose) {
        // If directory is already expanded and toggleClose=true, collapse it
        const newExpandedPaths = { ...this.expandedPathsMap };
        delete newExpandedPaths[normalizedPath];
        this.expandedPathsMap = newExpandedPaths;
      }
    },

    isDirectoryLoading(path) {
      return Boolean(this.loadingPathsMap[normalizePath(path)]);
    },

    getDirectoryContents(path) {
      return this.directoriesCache[path] || { trees: [], blobs: [], submodules: [] };
    },
    shouldRenderShowMore(itemPath, parentPath) {
      const cached = this.directoriesCache[parentPath];
      if (!cached) return false;

      const { trees, blobs, submodules, pageInfo } = cached;
      const lastItemPath = normalizePath([...trees, ...blobs, ...submodules].at(-1)?.path);
      return itemPath === lastItemPath && pageInfo?.hasNextPage;
    },
    triggerFocusFilterBar() {
      const filterBar = this.$refs.filterInput;
      if (filterBar && filterBar.$el) {
        this.trackEvent('focus_file_tree_browser_filter_bar_on_repository_page', {
          label: 'shortcut',
        });
        filterBar.focus();
      }
    },
    onFilterBarClick() {
      this.trackEvent('focus_file_tree_browser_filter_bar_on_repository_page', {
        label: 'click',
      });
    },
    filterInputTooltipTarget() {
      // The input might not always be available (i.e. when the FTB is in collapsed state)
      return this.$refs.filterInput?.$el;
    },
    siblingInfo(item) {
      const siblings = this.siblingMap.get(`${item.parentPath || ''}-${item.level}`);
      return [siblings.length, siblings.indexOf(item.id) + 1];
    },
    onTreeKeydown(event) {
      handleTreeKeydown(event);
    },
  },
  filterPlaceholder: s__('Repository|Filter files (*.vue, *.rb...)'),
};
</script>

<template>
  <section aria-labelledby="tree-list-heading" class="gl-flex gl-h-full gl-flex-col">
    <div class="gl-mb-3 gl-flex gl-items-center gl-gap-3">
      <file-tree-browser-toggle />
      <h3 id="tree-list-heading" class="gl-heading-3 gl-mb-0">
        {{ __('Files') }}
      </h3>
    </div>

    <div class="gl-relative gl-flex">
      <gl-icon name="filter" class="gl-absolute gl-left-3 gl-top-3" variant="subtle" />
      <gl-form-input
        ref="filterInput"
        v-model="filter"
        :aria-label="__('Filter input')"
        :aria-keyshortcuts="filterSearchShortcutKey"
        type="search"
        class="!gl-pl-7"
        :placeholder="$options.filterPlaceholder"
        @click="onFilterBarClick"
      />
      <gl-tooltip
        v-if="!shortcutsDisabled"
        custom-class="file-browser-filter-tooltip"
        :target="filterInputTooltipTarget"
      >
        {{ __('Focus on the filter bar') }}
        <shortcut
          class="gl-whitespace-nowrap"
          :shortcuts="$options.FOCUS_FILE_TREE_BROWSER_FILTER_BAR.defaultKeys"
        />
      </gl-tooltip>
    </div>
    <gl-loading-icon v-if="isRootLoading" class="gl-mt-5" />
    <nav
      v-else
      class="repository-tree-list gl-mt-2 gl-flex gl-min-h-0 gl-flex-col"
      :aria-label="__('File tree')"
    >
      <div
        v-if="filteredFlatFilesList.length"
        class="gl-h-full gl-min-h-0 gl-flex-grow gl-overflow-y-auto gl-pl-2"
        role="tree"
        @keydown="onTreeKeydown"
      >
        <file-row
          v-for="(item, index) in filteredFlatFilesList"
          :key="item.id + index"
          :file="item"
          :file-url="item.routerPath"
          :level="item.level"
          :opened="item.opened"
          :loading="item.loading"
          show-tree-toggle
          tabindex="-1"
          :aria-current="isCurrentPath(item.path)"
          role="treeitem"
          :aria-expanded="item.opened"
          :aria-selected="isCurrentPath(item.path)"
          :aria-level="item.level + 1"
          :aria-setsize="siblingInfo(item)[0]"
          :aria-posinset="siblingInfo(item)[1]"
          :style="{ '--level': item.level }"
          :class="{
            'tree-list-parent': item.level > 0,
            '!gl-bg-gray-50': isCurrentPath(item.path),
          }"
          class="gl-relative !gl-mx-0"
          truncate-middle
          @clickTree="(options) => toggleDirectory(item.path, options)"
          @showMore="fetchDirectory(item.parentPath)"
        />
      </div>
      <p v-else class="gl-my-6 gl-text-center">
        {{ __('No files found') }}
      </p>
    </nav>
  </section>
</template>

<style>
.file-browser-filter-tooltip .tooltip-inner {
  max-width: 210px;
}
</style>
