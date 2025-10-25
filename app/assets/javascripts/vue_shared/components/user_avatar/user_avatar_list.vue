<script>
import { GlButton } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';
import UserAvatarLink from './user_avatar_link.vue';

export default {
  components: {
    UserAvatarLink,
    GlButton,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    breakpoint: {
      type: Number,
      required: false,
      default: 10,
    },
    imgSize: {
      type: [Number, Object],
      required: true,
    },
    emptyText: {
      type: String,
      required: false,
      default: __('None'),
    },
    hasMore: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isExpanded: false,
    };
  },
  computed: {
    visibleItems() {
      if (!this.hasHiddenItems) {
        return this.items;
      }

      return this.items.slice(0, this.breakpoint);
    },
    hasHiddenItems() {
      return this.hasBreakpoint && !this.isExpanded && this.items.length > this.breakpoint;
    },
    hasBreakpoint() {
      return this.breakpoint > 0 && this.items.length > this.breakpoint;
    },
    expandText() {
      if (!this.hasHiddenItems && !this.hasMore) {
        return '';
      }

      if (this.hasMore) {
        return __('Load more');
      }

      const count = this.items.length - this.breakpoint;
      return sprintf(__('%{count} more'), { count });
    },
  },
  methods: {
    expand() {
      if (this.hasMore && !this.hasHiddenItems) {
        this.$emit('load-more');
      } else {
        this.isExpanded = true;
        this.$emit('expanded');
      }
    },
    collapse() {
      this.isExpanded = false;
      this.$emit('collapsed');
    },
  },
};
</script>

<template>
  <div v-if="!items.length">{{ emptyText }}</div>
  <div v-else>
    <user-avatar-link
      v-for="item in visibleItems"
      :key="item.id"
      :link-href="item.web_url || item.webUrl"
      :img-src="item.avatar_url || item.avatarUrl"
      :img-alt="item.name"
      :tooltip-text="item.name"
      :img-size="imgSize"
      :popover-user-id="item.id"
      :popover-username="item.username"
      img-css-classes="gl-mr-3"
    />
    <template v-if="hasBreakpoint || hasMore">
      <gl-button
        v-if="hasHiddenItems || hasMore"
        variant="link"
        :loading="isLoading"
        @click="expand"
      >
        {{ expandText }}
      </gl-button>
      <gl-button v-else variant="link" @click="collapse">
        {{ __('show less') }}
      </gl-button>
    </template>
  </div>
</template>
