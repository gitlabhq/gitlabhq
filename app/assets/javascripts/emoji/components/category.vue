<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIntersectionObserver } from '@gitlab/ui';
import { humanize } from '~/lib/utils/text_utility';
import EmojiGroup from './emoji_group.vue';

export default {
  components: {
    GlIntersectionObserver,
    EmojiGroup,
  },
  props: {
    category: {
      type: String,
      required: true,
    },
    emojis: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      renderGroup: false,
    };
  },
  computed: {
    categoryTitle() {
      return humanize(this.category);
    },
  },
  methods: {
    categoryAppeared() {
      this.renderGroup = true;
      this.$emit('appear', this.category);
    },
    onClick(emoji) {
      this.$emit('click', { category: this.category, emoji });
    },
  },
};
</script>

<template>
  <gl-intersection-observer class="gl-px-4 gl-h-full" @appear="categoryAppeared">
    <div class="gl-top-0 gl-py-3 gl-w-full gl-z-1 gl-font-sm emoji-picker-category-header">
      <b>{{ categoryTitle }}</b>
    </div>
    <template v-if="emojis.length">
      <emoji-group
        v-for="(emojiGroup, index) in emojis"
        :key="index"
        :emojis="emojiGroup"
        :render-group="renderGroup"
        @emoji-click="onClick"
      />
    </template>
    <p v-else>
      {{ s__('AwardEmoji|No emoji found.') }}
    </p>
  </gl-intersection-observer>
</template>
