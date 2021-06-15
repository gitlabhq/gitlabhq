<script>
import { GlIcon, GlDropdown, GlSearchBoxByType } from '@gitlab/ui';
import { findLastIndex } from 'lodash';
import VirtualList from 'vue-virtual-scroll-list';
import { CATEGORY_NAMES } from '~/emoji';
import { CATEGORY_ICON_MAP, FREQUENTLY_USED_KEY } from '../constants';
import Category from './category.vue';
import EmojiList from './emoji_list.vue';
import { addToFrequentlyUsed, getEmojiCategories, hasFrequentlyUsedEmojis } from './utils';

export default {
  components: {
    GlIcon,
    GlDropdown,
    GlSearchBoxByType,
    VirtualList,
    Category,
    EmojiList,
  },
  props: {
    toggleClass: {
      type: [Array, String, Object],
      required: false,
      default: () => [],
    },
    dropdownClass: {
      type: [Array, String, Object],
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      currentCategory: 0,
      searchValue: '',
    };
  },
  computed: {
    categoryNames() {
      return CATEGORY_NAMES.filter((c) => {
        if (c === FREQUENTLY_USED_KEY) return hasFrequentlyUsedEmojis();
        return true;
      }).map((category) => ({
        name: category,
        icon: CATEGORY_ICON_MAP[category],
      }));
    },
  },
  methods: {
    categoryAppeared(category) {
      this.currentCategory = category;
    },
    async scrollToCategory(categoryName) {
      const categories = await getEmojiCategories();
      const { top } = categories[categoryName];

      this.$refs.virtualScoller.setScrollTop(top);
    },
    selectEmoji(name) {
      this.$emit('click', name);
      this.$refs.dropdown.hide();
      addToFrequentlyUsed(name);
    },
    getBoundaryElement() {
      return document.querySelector('.content-wrapper') || 'scrollParent';
    },
    onSearchInput() {
      this.$refs.virtualScoller.setScrollTop(0);
      this.$refs.virtualScoller.forceRender();
    },
    async onScroll(event, { offset }) {
      const categories = await getEmojiCategories();

      this.currentCategory = findLastIndex(Object.values(categories), ({ top }) => offset >= top);
    },
  },
};
</script>

<template>
  <div class="emoji-picker">
    <gl-dropdown
      ref="dropdown"
      :toggle-class="toggleClass"
      :boundary="getBoundaryElement()"
      :class="dropdownClass"
      menu-class="dropdown-extended-height"
      category="secondary"
      no-flip
      right
      lazy
      @shown="$emit('shown')"
      @hidden="$emit('hidden')"
    >
      <template #button-content><slot name="button-content"></slot></template>
      <gl-search-box-by-type
        v-model="searchValue"
        class="gl-mx-5! gl-mb-2!"
        autofocus
        debounce="500"
        @input="onSearchInput"
      />
      <div
        v-show="!searchValue"
        class="gl-display-flex gl-mx-5 gl-border-b-solid gl-border-gray-100 gl-border-b-1"
      >
        <button
          v-for="(category, index) in categoryNames"
          :key="category.name"
          :class="{
            'gl-text-body! emoji-picker-category-active': index === currentCategory,
          }"
          type="button"
          class="gl-border-0 gl-border-b-2 gl-border-b-solid gl-flex-grow-1 gl-text-gray-300 gl-pt-3 gl-pb-3 gl-bg-transparent emoji-picker-category-tab"
          :aria-label="category.name"
          @click="scrollToCategory(category.name)"
        >
          <gl-icon :name="category.icon" :size="12" />
        </button>
      </div>
      <emoji-list :search-value="searchValue">
        <template #default="{ filteredCategories }">
          <virtual-list
            ref="virtualScoller"
            :size="258"
            :remain="1"
            :bench="2"
            variable
            :onscroll="onScroll"
          >
            <div
              v-for="(category, categoryKey) in filteredCategories"
              :key="categoryKey"
              :style="{ height: category.height + 'px' }"
            >
              <category :category="categoryKey" :emojis="category.emojis" @click="selectEmoji" />
            </div>
          </virtual-list>
        </template>
      </emoji-list>
    </gl-dropdown>
  </div>
</template>
