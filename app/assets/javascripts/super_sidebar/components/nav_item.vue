<script>
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
  },
  data() {
    return {
      expanded: this.item.is_active,
    };
  },
  computed: {
    collapseIcon() {
      return this.expanded ? 'chevron-up' : 'chevron-down';
    },
    isSection() {
      return Boolean(this.item?.items?.length);
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
          href: '#',
          'aria-hidden': true,
        };
      }
      return {
        href: this.item.link,
      };
    },
    linkClasses() {
      return {
        'gl-bg-t-gray-a-08': this.isActive,
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
    <a
      v-bind="linkProps"
      class="gl-rounded-base gl-relative gl-display-flex gl-py-3 gl-px-0 gl-line-height-normal gl-text-black-normal! gl-hover-bg-t-gray-a-08 gl-text-decoration-none!"
      :class="linkClasses"
      data-qa-selector="sidebar_menu_link"
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
      <div class="gl-pr-3">
        {{ item.title }}
        <div v-if="item.subtitle" class="gl-font-sm gl-text-gray-500 gl-mt-1">
          {{ item.subtitle }}
        </div>
      </div>
      <span v-if="isSection || hasPill" class="gl-flex-grow-1 gl-text-right gl-mr-3">
        <gl-badge v-if="hasPill" size="sm" variant="info">
          {{ pillData }}
        </gl-badge>
        <gl-icon v-else-if="isSection" :name="collapseIcon" />
      </span>
    </a>
    <gl-collapse v-if="isSection" :id="item.title" v-model="expanded">
      <ul class="gl-p-0">
        <nav-item
          v-for="subItem of item.items"
          :key="`${item.title}-${subItem.title}`"
          :item="subItem"
        />
      </ul>
    </gl-collapse>
  </li>
</template>
