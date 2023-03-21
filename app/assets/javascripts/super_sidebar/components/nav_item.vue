<script>
import { kebabCase } from 'lodash';
import { GlCollapse, GlIcon, GlBadge } from '@gitlab/ui';

export default {
  name: 'NavItem',
  components: {
    GlCollapse,
    GlIcon,
    GlBadge,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    linkClasses: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      expanded: this.item.is_active,
    };
  },
  computed: {
    elem() {
      return this.isSection ? 'button' : 'a';
    },
    collapseIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    isSection() {
      return Boolean(this.item?.items?.length);
    },
    itemId() {
      return kebabCase(this.item.title);
    },
    pillData() {
      return this.item.pill_count;
    },
    hasPill() {
      return (
        Number.isFinite(this.pillData) ||
        (typeof this.pillData === 'string' && this.pillData !== '')
      );
    },
    isActive() {
      if (this.isSection) {
        return !this.expanded && this.item.is_active;
      }
      return this.item.is_active;
    },
    linkProps() {
      if (this.isSection) {
        return {
          'aria-controls': this.itemId,
          'aria-expanded': String(this.expanded),
        };
      }
      return {
        ...this.$attrs,
        href: this.item.link,
        'aria-current': this.isActive ? 'page' : null,
      };
    },
    computedLinkClasses() {
      return {
        // Reset user agent styles on <button>
        'gl-appearance-none gl-border-0 gl-bg-transparent gl-text-left': this.isSection,
        'gl-w-full gl-focus': this.isSection,
        'gl-bg-t-gray-a-08': this.isActive,
        ...this.linkClasses,
      };
    },
  },
  methods: {
    click(event) {
      if (this.isSection) {
        event.preventDefault();
        this.expanded = !this.expanded;
      }
    },
  },
};
</script>

<template>
  <li>
    <component
      :is="elem"
      v-bind="linkProps"
      class="gl-rounded-base gl-relative gl-display-flex gl-align-items-center gl-py-3 gl-px-0 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-text-decoration-none!"
      :class="computedLinkClasses"
      data-qa-selector="sidebar_menu_link"
      data-testid="nav-item-link"
      :data-qa-menu-item="item.title"
      @click="click"
    >
      <div
        :class="[isActive ? 'gl-bg-blue-500' : 'gl-bg-transparent']"
        class="gl-absolute gl-left-2 gl-top-2 gl-bottom-2 gl-transition-slow"
        aria-hidden="true"
        style="width: 3px; border-radius: 3px; margin-right: 1px"
      ></div>
      <div class="gl-flex-shrink-0 gl-w-6 gl-mx-3">
        <slot name="icon">
          <gl-icon v-if="item.icon" :name="item.icon" class="gl-ml-2" />
        </slot>
      </div>
      <div class="gl-pr-3 gl-text-gray-900 gl-truncate-end">
        {{ item.title }}
        <div v-if="item.subtitle" class="gl-font-sm gl-text-gray-500 gl-truncate-end">
          {{ item.subtitle }}
        </div>
      </div>
      <span v-if="isSection || hasPill" class="gl-flex-grow-1 gl-text-right gl-mr-3">
        <gl-badge v-if="hasPill" size="sm" variant="info">
          {{ pillData }}
        </gl-badge>
        <gl-icon v-else-if="isSection" :name="collapseIcon" />
      </span>
    </component>
    <gl-collapse
      v-if="isSection"
      :id="itemId"
      v-model="expanded"
      :aria-label="item.title"
      class="gl-list-style-none gl-p-0"
      tag="ul"
    >
      <nav-item
        v-for="subItem of item.items"
        :key="`${item.title}-${subItem.title}`"
        :item="subItem"
      />
    </gl-collapse>
  </li>
</template>
