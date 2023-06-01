<script>
import { GlAvatar } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';
import { AUTOCOMPLETE_ERROR_MESSAGE } from '~/vue_shared/global_search/constants';

export default {
  name: 'CommandPaletteUserAutocompleteItem',
  components: {
    GlAvatar,
  },
  directives: {
    SafeHtml,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    searchQuery: {
      type: String,
      required: true,
    },
  },
  i18n: {
    AUTOCOMPLETE_ERROR_MESSAGE,
  },
  methods: {
    highlightedName(val) {
      return highlight(val, this.searchQuery);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <gl-avatar
      v-if="user.avatar_url"
      class="gl-mr-3"
      :src="user.avatar_url"
      :entity-id="user.id"
      :entity-name="user.text"
      :size="16"
      :shape="$options.AVATAR_SHAPE_OPTION_RECT"
      aria-hidden="true"
    />
    <span class="gl-display-flex gl-flex-direction-column">
      <span v-safe-html="highlightedName(user.text)" class="gl-text-gray-900"></span>
      <span v-safe-html="user.username" class="gl-font-sm gl-text-gray-500"></span>
    </span>
  </div>
</template>
