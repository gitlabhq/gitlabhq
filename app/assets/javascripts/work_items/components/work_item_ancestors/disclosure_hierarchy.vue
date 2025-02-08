<script>
import uniqueId from 'lodash/uniqueId';
import { GlIcon, GlTooltip, GlDisclosureDropdown, GlResizeObserverDirective } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import DisclosureHierarchyItem from './disclosure_hierarchy_item.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlIcon,
    GlTooltip,
    DisclosureHierarchyItem,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    /**
     * A list of items in the form:
     * ```
     * {
     *   title:    String, required
     *   icon:     String, optional
     * }
     * ```
     */
    items: {
      type: Array,
      required: false,
      default: () => [],
      validator: (items) => {
        return items.every((item) => Object.keys(item).includes('title'));
      },
    },
    /**
     * When set, displays only first and last item, and groups the rest under an ellipsis button
     */
    withEllipsis: {
      type: Boolean,
      default: false,
      required: false,
    },
    /**
     * When set, a tooltip displays when hovering middle ellipsis button
     */
    ellipsisTooltipLabel: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      itemUuid: uniqueId('disclosure-hierarchy-'),
      isMobile: false,
    };
  },
  computed: {
    middleItems() {
      if (this.isMobile) {
        return this.items.slice(0, -1).map((item) => ({ ...item, text: item.title }));
      }
      return this.items.slice(1, -1).map((item) => ({ ...item, text: item.title }));
    },
    firstItem() {
      return this.items[0];
    },
    lastItemIndex() {
      return this.items.length - 1;
    },
    lastItem() {
      return this.items[this.lastItemIndex];
    },
  },
  methods: {
    itemId(index) {
      return `${this.itemUuid}-item-${index}`;
    },
    handleResize() {
      this.isMobile = ['sm', 'xs'].includes(GlBreakpointInstance.getBreakpointSize());
    },
  },
};
</script>

<template>
  <div
    v-gl-resize-observer="handleResize"
    class="disclosure-hierarchy gl-relative gl-z-1 gl-flex gl-min-w-0 gl-grow-2"
  >
    <ul class="gl-relative gl-m-0 gl-inline-flex gl-max-w-full gl-list-none gl-flex-row gl-p-0">
      <template v-if="withEllipsis || isMobile">
        <disclosure-hierarchy-item v-if="!isMobile" :item="firstItem" :item-id="itemId(0)">
          <slot :item="firstItem" :item-id="itemId(0)"></slot>
        </disclosure-hierarchy-item>
        <li v-if="middleItems.length > 0" class="disclosure-hierarchy-item">
          <gl-disclosure-dropdown :items="middleItems">
            <template #toggle>
              <button
                id="disclosure-hierarchy-ellipsis-button"
                class="disclosure-hierarchy-button"
                :aria-label="ellipsisTooltipLabel"
              >
                <gl-icon name="ellipsis_h" class="gl-z-200 gl-ml-3" />
              </button>
            </template>
            <template #list-item="{ item }">
              <span class="gl-flex">
                <gl-icon
                  v-if="item.icon"
                  :name="item.icon"
                  class="gl-mr-3 gl-shrink-0 gl-align-middle"
                />
                {{ item.title }}
              </span>
            </template>
          </gl-disclosure-dropdown>
        </li>
        <gl-tooltip
          v-if="ellipsisTooltipLabel"
          target="disclosure-hierarchy-ellipsis-button"
          triggers="hover"
        >
          {{ ellipsisTooltipLabel }}
        </gl-tooltip>
        <disclosure-hierarchy-item :item="lastItem" :item-id="itemId(lastItemIndex)">
          <slot :item="lastItem" :item-id="itemId(lastItemIndex)"></slot>
        </disclosure-hierarchy-item>
      </template>
      <disclosure-hierarchy-item
        v-for="(item, index) in items"
        v-else
        :key="index"
        :item="item"
        :item-id="itemId(index)"
      >
        <slot :item="item" :item-id="itemId(index)"></slot>
      </disclosure-hierarchy-item>
    </ul>
  </div>
</template>
