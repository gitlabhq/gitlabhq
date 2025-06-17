<script>
import { GlAvatar, GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { AVATAR_SHAPE_OPTION_RECT, AVATAR_SHAPE_OPTION_CIRCLE } from '~/vue_shared/constants';
import { USER_CATEGORY_VALUE } from './constants';

export default {
  name: 'CommandPaletteSearchItem',
  components: {
    GlAvatar,
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    searchQuery: {
      type: String,
      required: true,
    },
  },
  computed: {
    highlightedName() {
      return highlight(this.item.text, this.searchQuery);
    },
    avatarShape() {
      return this.item.category === USER_CATEGORY_VALUE
        ? this.$options.AVATAR_SHAPE_OPTION_CIRCLE
        : this.$options.AVATAR_SHAPE_OPTION_RECT;
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
  AVATAR_SHAPE_OPTION_CIRCLE,
};
</script>

<template>
  <div class="gl-flex gl-items-center">
    <gl-avatar
      v-if="item.avatar_url !== undefined"
      class="gl-mr-3"
      :src="item.avatar_url"
      :entity-id="item.entity_id"
      :entity-name="item.entity_name"
      :size="16"
      :shape="avatarShape"
      aria-hidden="true"
    />
    <gl-icon v-if="item.icon" class="gl-mr-3 gl-shrink-0" :name="item.icon" />
    <span class="gl-flex gl-min-w-0 gl-items-center gl-gap-2">
      <span v-safe-html="highlightedName" class="gl-truncate gl-text-strong"></span>
      <span class="gl-text-subtle" aria-hidden="true">·</span>
      <span
        v-if="item.namespace"
        v-safe-html="item.namespace"
        class="gl-truncate gl-text-sm gl-text-subtle"
      ></span>
    </span>
  </div>
</template>
