<script>
import { GlTooltipDirective, GlLoadingIcon, GlFormInput, GlIcon } from '@gitlab/ui';
import micromatch from 'micromatch';
import { createAlert } from '~/alert';
import { RecycleScroller } from 'vendor/vue-virtual-scroller';
import FileRow from '~/vue_shared/components/file_row.vue';
import { s__, __ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import { TREE_PAGE_SIZE } from '~/repository/constants';
import { getRefType } from '~/repository/utils/ref_type';
import { normalizePath, dedupeByFlatPathAndId } from '../utils';

export default {
  ROW_HEIGHT: 32,
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlFormInput,
    GlIcon,
    RecycleScroller,
    FileRow,
    GlLoadingIcon,
  },
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
      currentPath: '/',
      directoriesCache: {},
      expandedPathsMap: {},
      loadingPathsMap: {},
    };
  },
  computed: {
    isRootLoading() {
      return this.isDirectoryLoading('/');
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
        micromatch.contains(item.path, pattern, { nocase: true }),
      );
    },
    flatFilesList() {
      if (this.isRootLoading) return [];
      return this.buildList('/', 0);
    },
  },
  mounted() {
    this.navigateTo(this.$route.params.path || '/');
  },
  methods: {
    isCurrentPath(path) {
      if (!this.$route.params.path) return path === '/';
      const routePath = normalizePath(this.$route.params.path);
      return path === routePath;
    },
    buildList(path, level) {
      const contents = this.getDirectoryContents(path);
      return this.processDirectories(contents.trees, path, level)
        .concat(this.processFiles(contents.blobs, level))
        .concat(this.processSubmodules(contents.submodules, level));
    },
    processDirectories(trees = [], path, level) {
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
          isCurrentPath: this.isCurrentPath(treePath),
        });

        // Recursively add children for expanded directories
        if (this.expandedPathsMap[treePath] && !this.isDirectoryLoading(treePath)) {
          directoryList.push(...this.buildList(treePath, level + 1));
        }
      });

      return directoryList;
    },
    processFiles(blobs = [], level) {
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
          isCurrentPath: this.isCurrentPath(blobPath),
        });
      });

      return filesList;
    },
    processSubmodules(submodules = [], level) {
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
          isCurrentPath: this.isCurrentPath(submodulePath),
        });
      });

      return submodulesList;
    },
    async fetchDirectory(dirPath) {
      const path = normalizePath(dirPath);
      const apiPath = path === '/' ? path : path.substring(1);

      if (this.directoriesCache[path] || this.loadingPathsMap[path]) return;

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
            nextPageCursor: '',
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

        this.directoriesCache = {
          ...this.directoriesCache,
          [path]: directoryContents,
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
    expandPathAncestors(path) {
      const normalizedPath = normalizePath(path);
      this.fetchDirectory('/');

      const segments = normalizedPath.split('/').filter(Boolean);
      let currentPath = '';

      // For each segment of the path, expand the parent directory
      segments.forEach((segment) => {
        currentPath += `/${segment}`;
        this.expandedPathsMap = {
          ...this.expandedPathsMap,
          [currentPath]: true,
        };
        this.fetchDirectory(currentPath);
      });
    },

    toggleDirectory(normalizedPath) {
      if (!this.expandedPathsMap[normalizedPath]) {
        // If directory is collapsed, expand it
        this.expandPathAncestors(normalizedPath);
        this.expandedPathsMap = {
          ...this.expandedPathsMap,
          [normalizedPath]: true,
        };
      } else {
        // If directory is already expanded, collapse it
        const newExpandedPaths = { ...this.expandedPathsMap };
        delete newExpandedPaths[normalizedPath];
        this.expandedPathsMap = newExpandedPaths;
      }
    },

    // Navigate to a specific directory or file
    navigateTo(path) {
      const normalizedPath = normalizePath(path);
      this.currentPath = normalizedPath;
      this.toggleDirectory(normalizedPath);
    },

    isDirectoryLoading(path) {
      return Boolean(this.loadingPathsMap[normalizePath(path)]);
    },

    getDirectoryContents(path) {
      return this.directoriesCache[normalizePath(path)] || { trees: [], blobs: [], submodules: [] };
    },
  },
  filterPlaceholder: s__('Repository|Filter (e.g. *.vue) (f)'),
};
</script>

<template>
  <section aria-labelledby="tree-list-heading" class="gl-flex gl-h-full gl-flex-col">
    <h3 id="tree-list-heading" class="gl-sr-only" :aria-label="__('File tree browser')">
      {{ __('Files') }}
    </h3>
    <div class="gl-relative gl-flex">
      <gl-icon name="filter" class="gl-absolute gl-left-3 gl-top-3" variant="subtle" />
      <gl-form-input
        v-model="filter"
        type="search"
        class="!gl-pl-7"
        :placeholder="$options.filterPlaceholder"
      />
    </div>
    <gl-loading-icon v-if="isRootLoading" class="gl-mt-5" />
    <nav v-else class="gl-mt-2 gl-flex gl-min-h-0 gl-flex-col" :aria-label="__('File tree')">
      <recycle-scroller
        v-if="filteredFlatFilesList.length"
        ref="scroller"
        :items="filteredFlatFilesList"
        :item-size="$options.ROW_HEIGHT"
        :buffer="100"
        key-field="id"
        class="gl-h-full gl-min-h-0 gl-flex-grow"
      >
        <template #default="{ item }">
          <file-row
            :file="item"
            :file-url="item.routerPath"
            :level="item.level"
            :opened="item.opened"
            :loading="item.loading"
            :style="{ '--level': item.level }"
            :class="{
              'tree-list-parent': item.level > 0,
              '!gl-bg-gray-50': item.isCurrentPath,
            }"
            class="!gl-mx-0"
            truncate-middle
            @clickTree="navigateTo(item.path)"
          />
        </template>
      </recycle-scroller>
      <p v-else class="gl-my-6 gl-text-center">
        {{ __('No files found') }}
      </p>
    </nav>
  </section>
</template>
