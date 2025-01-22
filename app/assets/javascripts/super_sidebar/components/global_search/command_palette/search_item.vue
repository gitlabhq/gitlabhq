<script>
import { GlAvatar, GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

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
  },
  AVATAR_SHAPE_OPTION_RECT,
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
      :size="item.avatar_size"
      :shape="$options.AVATAR_SHAPE_OPTION_RECT"
      aria-hidden="true"
    />
    <gl-icon v-if="item.icon" class="gl-mr-3 gl-shrink-0" :name="item.icon" />
    <span class="gl-flex gl-w-full gl-min-w-0 gl-flex-col">
      <span v-safe-html="highlightedName" class="gl-truncate gl-text-strong"></span>
      <span
        v-if="item.namespace"
        v-safe-html="item.namespace"
        class="gl-truncate gl-text-sm gl-text-subtle"
      ></span>
    </span>
  </div>
</template>
