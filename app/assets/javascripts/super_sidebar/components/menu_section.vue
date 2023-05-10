<script>
import { kebabCase } from 'lodash';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import NavItem from './nav_item.vue';

export default {
  name: 'MenuSection',
  components: {
    GlCollapse,
    GlIcon,
    NavItem,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    separated: {
      type: Boolean,
      required: false,
      default: false,
    },
    tag: {
      type: String,
      required: false,
      default: 'div',
    },
  },
  data() {
    return {
      isExpanded: Boolean(this.expanded || this.item.is_active),
    };
  },
  computed: {
    buttonProps() {
      return {
        'aria-controls': this.itemId,
        'aria-expanded': String(this.isExpanded),
        'data-qa-menu-item': this.item.title,
      };
    },
    collapseIcon() {
      return this.isExpanded ? 'chevron-up' : 'chevron-down';
    },
    computedLinkClasses() {
      return {
        'gl-bg-t-gray-a-08': this.isActive,
      };
    },
    isActive() {
      return !this.isExpanded && this.item.is_active;
    },
    itemId() {
      return kebabCase(this.item.title);
    },
  },
  watch: {
    isExpanded(newIsExpanded) {
      this.$emit('collapse-toggle', newIsExpanded);
    },
  },
};
</script>

<template>
  <component :is="tag">
    <button
      class="gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-mb-1 gl-py-3 gl-px-0 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-focus-bg-t-gray-a-08 gl-text-decoration-none! gl-appearance-none gl-border-0 gl-bg-transparent gl-text-left gl-w-full gl-focus--focus"
      :class="computedLinkClasses"
      data-qa-selector="menu_section_button"
      :data-qa-section-name="item.title"
      v-bind="buttonProps"
      @click="isExpanded = !isExpanded"
    >
      <span
        :class="[isActive ? 'gl-bg-blue-500' : 'gl-bg-transparent']"
        class="gl-absolute gl-left-2 gl-top-2 gl-bottom-2 gl-transition-slow"
        aria-hidden="true"
        style="width: 3px; border-radius: 3px; margin-right: 1px"
      ></span>
      <span class="gl-flex-shrink-0 gl-w-6 gl-mx-3">
        <slot name="icon">
          <gl-icon v-if="item.icon" :name="item.icon" class="gl-ml-2 item-icon" />
        </slot>
      </span>

      <span class="gl-pr-3 gl-text-gray-900 gl-truncate-end">
        {{ item.title }}
      </span>

      <span class="gl-flex-grow-1 gl-text-right gl-mr-3 gl-text-gray-400">
        <gl-icon :name="collapseIcon" />
      </span>
    </button>

    <gl-collapse
      :id="itemId"
      v-model="isExpanded"
      :aria-label="item.title"
      class="gl-list-style-none gl-p-0 gl-m-0 gl-transition-duration-medium gl-transition-timing-function-ease"
      data-qa-selector="menu_section"
      :data-qa-section-name="item.title"
      tag="ul"
    >
      <slot>
        <nav-item
          v-for="subItem of item.items"
          :key="`${item.title}-${subItem.title}`"
          :item="subItem"
          @pin-add="(itemId) => $emit('pin-add', itemId)"
          @pin-remove="(itemId) => $emit('pin-remove', itemId)"
        />
      </slot>
    </gl-collapse>
    <hr v-if="separated" aria-hidden="true" class="gl-mx-4 gl-my-2" />
  </component>
</template>
