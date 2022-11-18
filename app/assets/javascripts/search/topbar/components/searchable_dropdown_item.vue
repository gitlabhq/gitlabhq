<script>
import { GlDropdownItem, GlAvatar } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { AVATAR_SHAPE_OPTION_RECT } from '~/vue_shared/constants';

export default {
  name: 'SearchableDropdownItem',
  components: {
    GlDropdownItem,
    GlAvatar,
  },
  directives: {
    SafeHtml,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    selectedItem: {
      type: Object,
      required: true,
    },
    searchText: {
      type: String,
      required: false,
      default: '',
    },
    name: {
      type: String,
      required: true,
    },
    fullName: {
      type: String,
      required: true,
    },
  },
  computed: {
    isSelected() {
      return this.item.id === this.selectedItem.id;
    },
    truncatedNamespace() {
      return truncateNamespace(this.item[this.fullName]);
    },
    highlightedItemName() {
      return highlight(this.item[this.name], this.searchText);
    },
  },
  AVATAR_SHAPE_OPTION_RECT,
};
</script>

<template>
  <gl-dropdown-item
    is-check-item
    :is-checked="isSelected"
    is-check-centered
    @click="$emit('change', item)"
  >
    <div class="gl-display-flex gl-align-items-center">
      <gl-avatar
        :src="item.avatar_url"
        :entity-id="item.id"
        :entity-name="item[name]"
        :shape="$options.AVATAR_SHAPE_OPTION_RECT"
        :size="32"
      />
      <div class="gl-display-flex gl-flex-direction-column">
        <span v-safe-html="highlightedItemName" data-testid="item-title"></span>
        <span class="gl-font-sm gl-text-gray-700" data-testid="item-namespace">{{
          truncatedNamespace
        }}</span>
      </div>
    </div>
  </gl-dropdown-item>
</template>
