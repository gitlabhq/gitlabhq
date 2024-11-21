<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlIcon } from '@gitlab/ui';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { joinPaths } from '~/lib/utils/url_utility';
import { TRACKING_UNKNOWN_PANEL } from '~/super_sidebar/constants';
import { TRACKING_CLICK_COMMAND_PALETTE_ITEM, OVERLAY_GOTO } from '../command_palette/constants';
import FrequentItem from './frequent_item.vue';
import FrequentItemSkeleton from './frequent_item_skeleton.vue';
import SearchResultHoverLayover from './global_search_hover_overlay.vue';

export default {
  name: 'FrequentlyVisitedItems',
  i18n: {
    OVERLAY_GOTO,
  },
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlIcon,
    FrequentItem,
    FrequentItemSkeleton,
    SearchResultHoverLayover,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyStateText: {
      type: String,
      required: true,
    },
    groupName: {
      type: String,
      required: true,
    },
    viewAllItemsText: {
      type: String,
      required: true,
    },
    viewAllItemsIcon: {
      type: String,
      required: true,
    },
    viewAllItemsPath: {
      type: String,
      required: false,
      default: null,
    },
    items: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    formattedItems() {
      // Each item needs two different representations. One is for the
      // GlDisclosureDropdownItem, and the other is for the FrequentItem
      // renderer component inside it.
      return this.items.map((item) => ({
        forDropdown: {
          id: item.id,

          // The text field satsifies GlDisclosureDropdownItem's prop
          // validator, and the href field ensures it renders a link.
          text: item.name,
          href: joinPaths(gon.relative_url_root || '/', item.fullPath),
          extraAttrs: {
            'data-track-action': TRACKING_CLICK_COMMAND_PALETTE_ITEM,
            'data-track-label': item.id,
            'data-track-property': TRACKING_UNKNOWN_PANEL,
            'data-track-extra': JSON.stringify({ title: item.name }),
          },
        },
        forRenderer: {
          id: item.id,
          title: item.name,
          subtitle: truncateNamespace(item.namespace),
          avatar: item.avatarUrl,
        },
      }));
    },
    showEmptyState() {
      return !this.loading && this.formattedItems.length === 0;
    },
    viewAllItem() {
      return {
        text: this.viewAllItemsText,
        href: this.viewAllItemsPath,
      };
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group v-bind="$attrs">
    <template #group-label>{{ groupName }}</template>

    <gl-disclosure-dropdown-item v-if="loading">
      <frequent-item-skeleton />
    </gl-disclosure-dropdown-item>
    <template v-else>
      <gl-disclosure-dropdown-item
        v-for="item of formattedItems"
        :key="item.forDropdown.id"
        :item="item.forDropdown"
        class="show-on-focus-or-hover--context show-hover-layover"
        @action="$emit('action')"
      >
        <template #list-item><frequent-item :item="item.forRenderer" /></template>
      </gl-disclosure-dropdown-item>
    </template>

    <gl-disclosure-dropdown-item v-if="showEmptyState" class="gl-cursor-text">
      <span class="gl-mx-3 gl-my-3 gl-text-sm gl-text-subtle">{{ emptyStateText }}</span>
    </gl-disclosure-dropdown-item>

    <gl-disclosure-dropdown-item key="all" :item="viewAllItem" class="show-hover-layover">
      <template #list-item>
        <search-result-hover-layover :text-message="$options.i18n.OVERLAY_GOTO">
          <gl-icon :name="viewAllItemsIcon" class="!gl-w-6" />
          {{ viewAllItemsText }}
        </search-result-hover-layover>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown-group>
</template>
