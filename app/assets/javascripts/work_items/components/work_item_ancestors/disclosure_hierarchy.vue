<script>
import { uniqueId } from 'lodash-es';
import { GlIcon, GlTooltip, GlDisclosureDropdown, GlResizeObserverDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { titleInLinkSafeHtmlConfig } from '~/lib/dompurify';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import DisclosureHierarchyItem from './disclosure_hierarchy_item.vue';

export default {
  name: 'DisclosureHierarchy',
  components: {
    GlDisclosureDropdown,
    GlIcon,
    GlTooltip,
    DisclosureHierarchyItem,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
    SafeHtml,
  },
  mixins: [glSlotsMixin],
  titleInLinkSafeHtmlConfig,
  props: {
    /**
     * A list of items in the form:
     * ```
     * {
     *   titleHtml: String (rendered as HTML)
     *   title:     String (plain text; label for the collapsed ellipsis dropdown, where HTML can't be used)
     *   message:   String (rendered as plain text)
     *   icon:      String, optional
     * }
     * ```
     * Either a message, or both titleHtml and its plain-text title, must be provided.
     */
    items: {
      type: Array,
      required: false,
      default: () => [],
      validator: (items) => {
        return items.every((item) => (item.titleHtml && item.title) || item.message);
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
        return this.items
          .slice(0, -1)
          .map((item) => ({ ...item, text: item.title ?? item.message }));
      }
      return this.items.slice(1, -1).map((item) => ({ ...item, text: item.title ?? item.message }));
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
      this.isMobile = ['sm', 'xs'].includes(PanelBreakpointInstance.getBreakpointSize());
    },
  },
};
</script>

<template>
  <div
    v-gl-resize-observer="handleResize"
    class="disclosure-hierarchy gl-relative gl-z-2 gl-flex gl-min-w-0 gl-grow-2"
    data-testid="ancestors-breadcrumb"
  >
    <ul class="gl-relative gl-m-0 gl-inline-flex gl-max-w-full gl-list-none gl-flex-row gl-p-0">
      <template v-if="withEllipsis || isMobile">
        <disclosure-hierarchy-item v-if="!isMobile" :item="firstItem" :item-id="itemId(0)">
          <template v-if="glSlots().default" #default
            ><slot :item="firstItem" :item-id="itemId(0)"></slot
          ></template>
        </disclosure-hierarchy-item>
        <li v-if="middleItems.length > 0" class="disclosure-hierarchy-item">
          <gl-disclosure-dropdown :items="middleItems">
            <template #toggle>
              <button
                :id="`${itemUuid}-ellipsis-button`"
                ref="ellipsisButton"
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
                <span
                  v-if="item.titleHtml"
                  v-safe-html:[$options.titleInLinkSafeHtmlConfig]="item.titleHtml"
                ></span>
                <span v-else>{{ item.message }}</span>
              </span>
            </template>
          </gl-disclosure-dropdown>
        </li>
        <gl-tooltip
          v-if="ellipsisTooltipLabel && middleItems.length > 0"
          :target="() => $refs.ellipsisButton"
          triggers="hover"
        >
          {{ ellipsisTooltipLabel }}
        </gl-tooltip>
        <disclosure-hierarchy-item :item="lastItem" :item-id="itemId(lastItemIndex)">
          <template v-if="glSlots().default" #default
            ><slot :item="lastItem" :item-id="itemId(lastItemIndex)"></slot
          ></template>
        </disclosure-hierarchy-item>
      </template>
      <disclosure-hierarchy-item
        v-for="(item, index) in items"
        v-else
        :key="index"
        :item="item"
        :item-id="itemId(index)"
      >
        <template v-if="glSlots().default" #default
          ><slot :item="item" :item-id="itemId(index)"></slot
        ></template>
      </disclosure-hierarchy-item>
    </ul>
  </div>
</template>
