<script>
import { GlButton, GlIcon, GlBadge, GlLoadingIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlIcon,
    GlBadge,
    GlLoadingIcon,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    count: {
      type: [String, Number],
      required: false,
      default: '',
    },
    icon: {
      type: String,
      required: false,
      default: null,
    },
    toggleText: {
      type: String,
      required: false,
      default: null,
    },
    toggleAriaLabel: {
      type: String,
      required: false,
      default: null,
    },
    isCollapsible: {
      type: Boolean,
      required: false,
      default: false,
    },
    collapsed: {
      type: Boolean,
      required: false,
      default: false,
    },
    containerTag: {
      type: String,
      required: false,
      default: 'section',
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    anchorId: {
      type: String,
      required: false,
      default: '',
    },
    headerClass: {
      type: [String, Object],
      required: false,
      default: null,
    },
    titleClass: {
      type: [String, Object],
      required: false,
      default: null,
    },
    bodyClass: {
      type: [String, Object],
      required: false,
      default: null,
    },
    footerClass: {
      type: [String, Object],
      required: false,
      default: null,
    },
    persistCollapsedState: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isCollapsed:
        this.collapsed ||
        (this.persistCollapsedState &&
          localStorage.getItem(this.getLocalStorageKeyName()) === 'true'),
      isFormVisible: false,
    };
  },
  computed: {
    isContentVisible() {
      const hasContent =
        this.$scopedSlots.default || this.$scopedSlots.empty || this.$scopedSlots.pagination;
      return !(hasContent && this.isCollapsible && this.isCollapsed);
    },
    toggleIcon() {
      return this.isCollapsed ? 'chevron-lg-down' : 'chevron-lg-up';
    },
    toggleLabel() {
      return this.isCollapsed ? __('Expand') : __('Collapse');
    },
    ariaExpandedAttr() {
      return this.isCollapsed ? 'false' : 'true';
    },
    displayedCount() {
      if (this.isLoading) {
        return '...';
      }

      return this.icon && !this.count ? '0' : this.count;
    },
    isFormUsedAndVisible() {
      return this.$scopedSlots.form && this.isFormVisible && !this.isCollapsed;
    },
  },
  watch: {
    collapsed: {
      handler(newVal) {
        this.isCollapsed = newVal > 0;
      },
    },
  },
  methods: {
    toggleCollapse() {
      this.isCollapsed = !this.isCollapsed;

      if (this.isCollapsed) {
        this.$emit('collapsed');
      } else {
        this.$emit('expanded');
      }

      if (this.persistCollapsedState) {
        localStorage.setItem(this.getLocalStorageKeyName(), this.isCollapsed);
      }
    },
    showForm() {
      this.isFormVisible = true;
      this.isCollapsed = false;
      this.$emit('showForm');
    },
    hideForm() {
      this.isFormVisible = false;
      this.$emit('hideForm');
    },
    getLocalStorageKeyName() {
      return `crud-collapse-${this.anchorId}`;
    },
  },
};
</script>

<template>
  <component
    :is="containerTag"
    :id="anchorId"
    ref="crudComponent"
    class="crud gl-border gl-rounded-base gl-border-section gl-bg-subtle"
    :class="{ 'gl-mt-5': isCollapsible }"
  >
    <header
      class="crud-header gl-border-b gl-relative gl-flex gl-flex-wrap gl-justify-between gl-gap-x-5 gl-gap-y-2 gl-rounded-t-base gl-border-section gl-bg-section gl-px-5 gl-py-4"
      :class="[
        headerClass,
        {
          'gl-rounded-base gl-border-b-transparent': !isContentVisible,
          'gl-relative gl-pr-10': isCollapsible,
        },
      ]"
    >
      <div class="gl-flex gl-grow gl-flex-col gl-self-center">
        <button
          v-if="isCollapsible"
          tabindex="-1"
          aria-hidden="true"
          class="gl-z-0 gl-m-0 gl-h-0 gl-border-none gl-p-0"
          @click="toggleCollapse"
        >
          <span class="gl-absolute gl-inset-0"></span>
        </button>
        <h2
          class="gl-m-0 gl-inline-flex gl-items-center gl-gap-3 gl-text-base gl-font-bold gl-leading-normal"
          :class="titleClass"
          data-testid="crud-title"
        >
          <gl-link
            v-if="anchorId"
            class="anchor gl-absolute gl-z-1 gl-no-underline"
            :href="`#${anchorId}`"
            :aria-labelledby="anchorId"
          />
          <slot v-if="$scopedSlots.title" name="title"></slot>
          <template v-else>{{ title }}</template>

          <span
            v-if="displayedCount || $scopedSlots.count"
            class="crud-count gl-inline-flex gl-items-center gl-gap-2 gl-self-start gl-text-sm gl-text-subtle"
            data-testid="crud-count"
          >
            <template v-if="displayedCount">
              <gl-icon v-if="icon" :name="icon" variant="subtle" data-testid="crud-icon" />
              <template v-if="icon">{{ displayedCount }}</template>
              <gl-badge v-else class="gl-self-baseline">{{ displayedCount }}</gl-badge>
            </template>
            <slot v-if="$scopedSlots.count" name="count"></slot>
          </span>
        </h2>
        <p
          v-if="description || $scopedSlots.description"
          class="!gl-mb-0 !gl-mt-2 !gl-text-sm !gl-leading-normal !gl-text-subtle"
          data-testid="crud-description"
        >
          <slot v-if="$scopedSlots.description" name="description"></slot>
          <template v-else>{{ description }}</template>
        </p>
      </div>
      <div class="gl-z-1 gl-flex gl-items-center gl-gap-3" data-testid="crud-actions">
        <slot name="actions" :show-form="showForm"></slot>
        <gl-button
          v-if="toggleText && !isFormUsedAndVisible"
          size="small"
          :aria-label="toggleAriaLabel"
          data-testid="crud-form-toggle"
          @click="showForm"
          >{{ toggleText }}</gl-button
        >
        <div
          v-if="isCollapsible"
          class="gl-border-l gl-pointer-events-none gl-absolute gl-right-5 gl-top-4 gl-h-6 gl-border-l-section gl-pl-3"
        >
          <gl-button
            v-gl-tooltip
            :title="toggleLabel"
            :icon="toggleIcon"
            category="tertiary"
            size="small"
            :aria-label="toggleLabel"
            :aria-expanded="ariaExpandedAttr"
            :aria-controls="anchorId"
            class="gl-pointer-events-auto -gl-mr-2 gl-self-start"
            data-testid="crud-collapse-toggle"
            @click="toggleCollapse"
          />
        </div>
      </div>
    </header>

    <div
      v-if="isFormUsedAndVisible"
      class="gl-border-b gl-border-section gl-bg-subtle gl-p-5 gl-pt-4"
      data-testid="crud-form"
    >
      <slot name="form" :hide-form="hideForm"></slot>
    </div>

    <div
      v-if="isContentVisible"
      class="crud-body gl-mx-5 gl-my-4"
      :class="[bodyClass, { 'gl-rounded-b-base': !$scopedSlots.footer }]"
      data-testid="crud-body"
    >
      <gl-loading-icon v-if="isLoading" size="sm" data-testid="crud-loading" />
      <span v-else-if="$scopedSlots.empty" class="gl-text-subtle" data-testid="crud-empty">
        <slot name="empty"></slot>
      </span>
      <slot v-else :show-form="showForm"></slot>

      <div
        v-if="$scopedSlots.pagination"
        class="crud-pagination gl-border-t gl-flex gl-justify-center gl-border-t-section gl-p-5"
        data-testid="crud-pagination"
      >
        <slot name="pagination"></slot>
      </div>
    </div>

    <footer
      v-if="isContentVisible && $scopedSlots.footer"
      class="gl-border-t gl-rounded-b-base gl-border-section gl-bg-section gl-px-5 gl-py-4"
      :class="footerClass"
      data-testid="crud-footer"
    >
      <slot name="footer"></slot>
    </footer>
  </component>
</template>
