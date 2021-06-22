<script>
import { GlDropdownItem, GlAvatar, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import highlight from '~/lib/utils/highlight';
import { truncateNamespace } from '~/lib/utils/text_utility';

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
};
</script>

<template>
  <gl-dropdown-item
    :is-check-item="true"
    :is-checked="isSelected"
    :is-check-centered="true"
    @click="$emit('change', item)"
  >
    <div class="gl-display-flex gl-align-items-center">
      <gl-avatar
        :src="item.avatar_url"
        :entity-id="item.id"
        :entity-name="item[name]"
        shape="rect"
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
