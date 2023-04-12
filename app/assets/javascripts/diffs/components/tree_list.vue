<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import { mapActions, mapGetters, mapState } from 'vuex';
import micromatch from 'micromatch';
import { debounce } from 'lodash';
import { getModifierKey } from '~/constants';
import { s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { RecycleScroller } from 'vendor/vue-virtual-scroller';
import DiffFileRow from './diff_file_row.vue';

const MODIFIER_KEY = getModifierKey();

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlIcon,
    DiffFileRow,
    RecycleScroller,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    hideFileStats: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      search: '',
      scrollerHeight: 0,
      resizeObserver: null,
      rowHeight: 0,
      debouncedHeightCalc: null,
    };
  },
  computed: {
    ...mapState('diffs', ['tree', 'renderTreeList', 'currentDiffFileId', 'viewedDiffFileIds']),
    ...mapGetters('diffs', ['allBlobs']),
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
      const createFlatten = (level) => (item) => {
        result.push({
          ...item,
          level: item.isHeader ? 0 : level,
          key: item.key || item.path,
        });
        if (item.opened || item.isHeader) {
          item.tree.forEach(createFlatten(level + 1));
        }
      };

      this.filteredTreeList.forEach(createFlatten(0));

      return result;
    },
  },
  created() {
    this.debouncedHeightCalc = debounce(this.calculateScrollerHeight, 50);
  },
  mounted() {
    const heightProp = getComputedStyle(this.$refs.wrapper).getPropertyValue('--file-row-height');
    this.rowHeight = parseInt(heightProp, 10);
    this.calculateScrollerHeight();
    this.resizeObserver = new ResizeObserver(() => {
      this.debouncedHeightCalc();
    });
    this.resizeObserver.observe(this.$refs.scrollRoot);
  },
  beforeDestroy() {
    this.resizeObserver.disconnect();
  },
  methods: {
    ...mapActions('diffs', ['toggleTreeOpen', 'goToFile']),
    clearSearch() {
      this.search = '';
    },
    calculateScrollerHeight() {
      this.scrollerHeight = this.$refs.scrollRoot.clientHeight;
    },
  },
  searchPlaceholder: sprintf(s__('MergeRequest|Search (e.g. *.vue) (%{MODIFIER_KEY}P)'), {
    MODIFIER_KEY,
  }),
  DiffFileRow,
};
</script>

<template>
  <div
    ref="wrapper"
    class="tree-list-holder d-flex flex-column"
    data-qa-selector="file_tree_container"
  >
    <div class="gl-pb-3 position-relative tree-list-search d-flex">
      <div class="flex-fill d-flex">
        <gl-icon name="search" class="gl-absolute gl-top-5 tree-list-icon" />
        <label for="diff-tree-search" class="sr-only">{{ $options.searchPlaceholder }}</label>
        <input
          id="diff-tree-search"
          v-model="search"
          :placeholder="$options.searchPlaceholder"
          type="search"
          name="diff-tree-search"
          class="form-control"
          data-testid="diff-tree-search"
          data-qa-selector="diff_tree_search"
        />
        <button
          v-show="search"
          :aria-label="__('Clear search')"
          type="button"
          class="position-absolute bg-transparent tree-list-icon tree-list-clear-icon border-0 p-0"
          @click="clearSearch"
        >
          <gl-icon name="close" />
        </button>
      </div>
    </div>
    <div
      ref="scrollRoot"
      :class="{ 'tree-list-blobs': !renderTreeList || search }"
      class="gl-flex-grow-1 mr-tree-list"
    >
      <recycle-scroller
        v-if="flatFilteredTreeList.length"
        :style="{ height: `${scrollerHeight}px` }"
        :items="flatFilteredTreeList"
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
            @clickFile="(path) => goToFile({ singleFile: glFeatures.singleFileFileByFile, path })"
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
  </div>
</template>

<style>
.tree-list-blobs .file-row-name {
  margin-left: 12px;
}

.diff-tree-search-shortcut {
  top: 50%;
  right: 10px;
  transform: translateY(-50%);
  pointer-events: none;
}

.tree-list-icon:not(button) {
  pointer-events: none;
}
</style>
