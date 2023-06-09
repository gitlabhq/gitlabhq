<script>
import { GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';

export default {
  name: 'CommandPaletteCommandAutocompleteItem',
  components: {
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    command: {
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
      return highlight(this.command.text, this.searchQuery);
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center">
    <gl-icon v-if="command.icon" class="gl-mr-3" :name="command.icon" />
    <span v-safe-html="highlightedName" class="gl-text-gray-900"></span>
  </div>
</template>
