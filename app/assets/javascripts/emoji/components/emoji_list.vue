<script>
import { chunk } from 'lodash';
import { searchEmoji } from '~/emoji';
import { EMOJIS_PER_ROW } from '../constants';
import { getEmojiCategories, generateCategoryHeight } from './utils';

export default {
  props: {
    searchValue: {
      type: String,
      required: true,
    },
  },
  data() {
    return { render: false };
  },
  computed: {
    filteredCategories() {
      if (this.searchValue !== '') {
        const emojis = chunk(
          searchEmoji(this.searchValue).map(({ emoji }) => emoji.name),
          EMOJIS_PER_ROW,
        );

        return {
          search: { emojis, height: generateCategoryHeight(emojis.length) },
        };
      }

      return this.categories;
    },
  },
  async mounted() {
    this.categories = await getEmojiCategories();
    this.render = true;
  },
};
</script>

<template>
  <div v-if="render">
    <slot :filtered-categories="filteredCategories"></slot>
  </div>
</template>
