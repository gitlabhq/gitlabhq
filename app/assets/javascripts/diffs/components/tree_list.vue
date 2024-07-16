<script>
import {
  GlTooltipDirective,
  GlBadge,
  GlButtonGroup,
  GlButton,
  GlSearchBoxByType,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import micromatch from 'micromatch';
import { getModifierKey } from '~/constants';
import { s__, sprintf } from '~/locale';
import { RecycleScroller } from 'vendor/vue-virtual-scroller';
import DiffFileRow from './diff_file_row.vue';
import TreeListHeight from './tree_list_height.vue';

const MODIFIER_KEY = getModifierKey();

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlBadge,
    GlButtonGroup,
    GlButton,
    TreeListHeight,
    DiffFileRow,
    RecycleScroller,
    GlSearchBoxByType,
  },
  props: {
    hideFileStats: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      search: '',
    };
  },
  computed: {
    ...mapState('diffs', [
      'tree',
      'renderTreeList',
      'currentDiffFileId',
      'viewedDiffFileIds',
      'realSize',
    ]),
    ...mapGetters('diffs', ['allBlobs', 'pinnedFile']),
    filteredTreeList() {
      let search = this.search.toLowerCase().trim();

      if (search === '') {
        return this.renderTreeList ? this.tree : this.allBlobs;
      }

      const searchSplit = search.split(',').filter((t) => t);

      if (searchSplit.length > 1) {
        search = `(${searchSplit.map((s) => s.replace(/(^ +| +$)/g, '')).join('|')})`;
      } else {
        [search] = searchSplit;
      }

      return this.allBlobs.reduce((acc, folder) => {
        const tree = folder.tree.filter((f) =>
          micromatch.contains(f.path, search, { nocase: true }),
        );

        if (tree.length) {
          return acc.concat({
            ...folder,
            tree,
          });
        }

        return acc;
      }, []);
    },
    // Flatten the treeList so there's no nested trees
    // This gives us fixed row height for virtual scrolling
    // in:  [{ path: 'a', tree: [{ path: 'b' }] }, { path: 'c' }]
    // out: [{ path: 'a', tree: [{ path: 'b' }] }, { path: 'b' }, { path: 'c' }]
    flatFilteredTreeList() {
      const result = [];
      const createFlatten = (level, hidden) => (item) => {
        result.push({
          ...item,
          hidden,
          level: item.isHeader ? 0 : level,
          key: item.key || item.path,
        });
        const isHidden = hidden || (item.type === 'tree' && !item.opened);
        item.tree.forEach(createFlatten(level + 1, isHidden));
      };

      this.filteredTreeList.forEach(createFlatten(0));

      return result;
    },
    flatListWithPinnedFile() {
      const result = [...this.flatFilteredTreeList];
      const pinnedIndex = result.findIndex((item) => item.path === this.pinnedFile.file_path);
      const [pinnedItem] = result.splice(pinnedIndex, 1);

      if (pinnedItem.parentPath === '/')
        return [{ ...pinnedItem, level: 0, pinned: true, hidden: false }, ...result];

      // remove detached folder from the tree
      const next = result[pinnedIndex];
      const prev = result[pinnedIndex - 1];
      const hasContainingFolder =
        prev && prev.type === 'tree' && prev.level === pinnedItem.level - 1;
      const hasSibling = next && next.type !== 'tree' && next.level === pinnedItem.level;
      if (hasContainingFolder && !hasSibling) {
        // folder tree is always condensed so we only need to remove the parent folder
        result.splice(pinnedIndex - 1, 1);
      }

      return [
        {
          level: 0,
          key: 'pinned-path',
          isHeader: true,
          opened: true,
          path: pinnedItem.parentPath,
          type: 'tree',
          hidden: false,
        },
        { ...pinnedItem, level: 1, pinned: true, hidden: false },
        ...result,
      ];
    },
    treeList() {
      const list = this.pinnedFile ? this.flatListWithPinnedFile : this.flatFilteredTreeList;
      if (this.search) return list;
      return list.filter((item) => !item.hidden);
    },
  },
  methods: {
    ...mapActions('diffs', ['toggleTreeOpen', 'goToFile', 'setRenderTreeList']),
  },
  searchPlaceholder: sprintf(s__('MergeRequest|Search (e.g. *.vue) (%{MODIFIER_KEY}P)'), {
    MODIFIER_KEY,
  }),
};
</script>

<template>
  <div class="tree-list-holder gl-flex flex-column" data-testid="file-tree-container">
    <div class="gl-flex gl-items-center gl-mb-3">
      <h5 class="gl-display-inline-block gl-my-0">{{ __('Files') }}</h5>
      <gl-badge class="gl-ml-2" data-testid="file-count">{{ realSize }}</gl-badge>
      <gl-button-group class="gl-ml-auto">
        <gl-button
          v-gl-tooltip.hover
          icon="list-bulleted"
          :selected="!renderTreeList"
          :title="__('List view')"
          :aria-label="__('List view')"
          data-testid="list-view-toggle"
          @click="setRenderTreeList({ renderTreeList: false })"
        />
        <gl-button
          v-gl-tooltip.hover
          icon="file-tree"
          :selected="renderTreeList"
          :title="__('Tree view')"
          :aria-label="__('Tree view')"
          data-testid="tree-view-toggle"
          @click="setRenderTreeList({ renderTreeList: true })"
        />
      </gl-button-group>
    </div>
    <label for="diff-tree-search" class="sr-only">{{ $options.searchPlaceholder }}</label>
    <gl-search-box-by-type
      id="diff-tree-search"
      v-model="search"
      :placeholder="$options.searchPlaceholder"
      name="diff-tree-search"
      data-testid="diff-tree-search"
      :clear-button-title="__('Clear search')"
      class="gl-mb-3"
    />
    <tree-list-height class="gl-flex-grow-1 gl-min-h-0" :items-count="treeList.length">
      <template #default="{ scrollerHeight, rowHeight }">
        <div :class="{ 'tree-list-blobs': !renderTreeList || search }" class="mr-tree-list">
          <recycle-scroller
            v-if="treeList.length"
            :style="{ height: `${scrollerHeight}px` }"
            :items="treeList"
            :item-size="rowHeight"
            :buffer="100"
            key-field="key"
          >
            <template #default="{ item }">
              <diff-file-row
                :file="item"
                :level="item.level"
                :viewed-files="viewedDiffFileIds"
                :hide-file-stats="hideFileStats"
                :current-diff-file-id="currentDiffFileId"
                :style="{ '--level': item.level }"
                :class="{ 'tree-list-parent': item.level > 0 }"
                class="gl-relative"
                @toggleTreeOpen="toggleTreeOpen"
                @clickFile="(path) => goToFile({ path })"
              />
            </template>
            <template #after>
              <div class="tree-list-gutter"></div>
            </template>
          </recycle-scroller>
          <p v-else class="prepend-top-20 append-bottom-20 text-center">
            {{ s__('MergeRequest|No files found') }}
          </p>
        </div>
      </template>
    </tree-list-height>
  </div>
</template>

<style>
.tree-list-blobs .file-row-name {
  margin-left: 12px;
}
</style>
