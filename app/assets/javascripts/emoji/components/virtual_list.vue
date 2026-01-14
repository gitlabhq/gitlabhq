<script>
import Category from './category.vue';

export default {
  name: 'VirtualList',
  components: {
    Category,
  },
  props: {
    searchTerm: {
      type: String,
      required: false,
      default: '',
    },
    categories: {
      type: Object,
      required: true,
    },
    scrollTop: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  emits: ['select-emoji', 'scroll'],
  computed: {
    categoryList() {
      return Object.entries(this.categories).map(([key, category]) => ({
        key,
        ...category,
      }));
    },
    buffer() {
      return this.$options.areaHeight * 2;
    },
    isSearching() {
      return this.searchTerm && typeof this.searchTerm === 'string';
    },
    visibleItems() {
      // Searching is just one category, and usually a subset of items
      // which is simpler to render them all.
      if (this.isSearching) return this.categoryList;

      return this.categoryList.filter((item) => {
        const itemTop = item.top;
        const itemBottom = itemTop + item.height;
        const viewportTop = this.scrollTop - this.buffer;
        const viewportBottom = this.scrollTop + this.$options.areaHeight + this.buffer;

        // We only show categories that have overlaps with the current view.
        return itemBottom > viewportTop && itemTop < viewportBottom;
      });
    },
  },
  watch: {
    scrollTop(newValue) {
      if (this.$refs.container && typeof newValue === 'number') {
        this.$refs.container.scrollTop = newValue;
      }
    },
  },
  methods: {
    handleScroll(e) {
      this.$emit('scroll', { offset: e.target.scrollTop });
    },
  },
  // Harcoded to set the height and easier computation of emojis visibility
  areaHeight: 253,
};
</script>

<template>
  <div
    ref="container"
    data-testid="virtual-list-container"
    class="gl-overflow-y-auto"
    :style="{ height: `${$options.areaHeight}px` }"
    @scroll="handleScroll"
  >
    <div
      v-for="item in categoryList"
      :key="item.key"
      :style="{ height: `${item.height}px` }"
      data-testid="category-wrapper"
    >
      <category
        v-show="visibleItems.some((v) => v.key === item.key)"
        :category="item.key"
        :emojis="item.emojis"
        @click="$emit('select-emoji', $event)"
      />
    </div>
  </div>
</template>
