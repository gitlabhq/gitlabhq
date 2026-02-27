<script>
import {
  GlButton,
  GlIcon,
  GlSkeletonLoader,
  GlLink,
  GlTooltipDirective,
  GlAnimatedChevronLgDownUpIcon,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    GlLink,
    GlAnimatedChevronLgDownUpIcon,
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
    /**
     * Use `v-show` instead of `v-if` to show/hide collapsed content.
     * This will prevent the content from being removed from the page entirely, which
     * can cause loss of internal state for collapsed components.
     * This behaviour defaults to true as of 18.9:
     * https://gitlab.com/gitlab-org/gitlab/-/issues/581227
     */
    keepAliveCollapsedContent: {
      type: Boolean,
      required: false,
      default: true,
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
    showZeroCount: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isCollapsed:
        (this.collapsed && !this.persistCollapsedState) ||
        (this.persistCollapsedState &&
          localStorage.getItem(this.getLocalStorageKeyName()) === 'true'),
      isFormVisible: false,
    };
  },
  computed: {
    isContentVisible() {
      return !(this.isCollapsible && this.isCollapsed);
    },
    toggleLabel() {
      return this.isCollapsed ? __('Expand') : __('Collapse');
    },
    ariaExpandedAttr() {
      return this.isCollapsed ? 'false' : 'true';
    },
    displayedCount() {
      if (this.isLoading) {
        return null;
      }

      if (this.count) {
        return this.count;
      }

      if (this.icon || this.showZeroCount) {
        return '0';
      }

      return null;
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
  mounted() {
    const localStorageValue = localStorage.getItem(this.getLocalStorageKeyName());

    if (this.persistCollapsedState) {
      // If collapsed by default and not yet toggled.
      if (this.collapsed && localStorageValue === null) {
        this.isCollapsed = true;
      }

      if (localStorageValue === 'true') {
        this.$emit('collapsed');
      } else if (localStorageValue) {
        this.$emit('expanded');
      }
    }
  },
  methods: {
    toggleCollapse() {
      this.isCollapsed = !this.isCollapsed;

      if (this.isCollapsed) {
        this.$emit('collapsed');
        /**
         * note that these separate `click-*` emits are necessary for tracking
         * this because the expanded and collapsed emits are programmatically
         * called on mount as part of persisted collapse state management. If
         * we just used the existing emits we would get tons of false positives
         * on page loads.
         */
        this.$emit('click-collapsed');
      } else {
        this.$emit('expanded');
        /**
         * note that these separate `click-*` emits are necessary for tracking
         * this because the expanded and collapsed emits are programmatically
         * called on mount as part of persisted collapse state management. If
         * we just used the existing emits we would get tons of false positives
         * on page loads.
         */
        this.$emit('click-expanded');
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
    class="crud gl-border gl-rounded-xl gl-border-transparent gl-bg-strong gl-px-2 contrast-more:gl-border-strong"
    :class="{ 'gl-mt-3': isCollapsible, 'gl-pb-2': isContentVisible }"
  >
    <header
      class="crud-header gl-relative gl-flex gl-flex-wrap gl-justify-between gl-gap-x-5 gl-gap-y-2 gl-rounded-t-lg gl-py-0 gl-pl-3 gl-pr-2 @md/panel:gl-flex-nowrap"
      :class="[
        headerClass,
        {
          'gl-relative gl-pr-9': isCollapsible,
        },
      ]"
    >
      <div class="gl-flex gl-grow gl-flex-col gl-self-center gl-py-3">
        <h2
          class="gl-mx-0 gl-my-2 gl-inline-flex gl-items-center gl-gap-3 gl-text-base gl-font-bold gl-leading-normal gl-text-heading"
          :class="titleClass"
          data-testid="crud-title"
        >
          <gl-link
            v-if="anchorId"
            class="anchor gl-absolute gl-no-underline"
            :href="`#${anchorId}`"
            :aria-labelledby="anchorId"
          />
          <slot name="title">
            {{ title }}
          </slot>

          <span
            v-if="displayedCount || $scopedSlots.count"
            class="crud-count gl-inline-flex gl-items-center gl-gap-2 gl-self-start gl-text-sm gl-font-normal gl-text-subtle"
            data-testid="crud-count"
          >
            <template v-if="displayedCount">
              <gl-icon v-if="icon" :name="icon" variant="subtle" data-testid="crud-icon" />
              {{ displayedCount }}
            </template>
            <slot v-if="$scopedSlots.count" name="count"></slot>
          </span>
        </h2>
        <p
          v-if="description || $scopedSlots.description"
          class="!gl-mb-0 !gl-text-sm !gl-leading-normal !gl-text-subtle"
          data-testid="crud-description"
        >
          <slot name="description">
            {{ description }}
          </slot>
        </p>
      </div>
      <div class="gl-my-3 gl-flex gl-items-start gl-gap-3" data-testid="crud-actions">
        <slot name="actions" :show-form="showForm" :is-form-visible="isFormVisible"></slot>
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
          class="gl-border-l gl-absolute gl-right-3 gl-top-1/2 gl-flex gl-h-5 -gl-translate-y-1/2 gl-items-center gl-border-strong gl-pl-3"
        >
          <gl-button
            v-gl-tooltip
            :title="toggleLabel"
            category="tertiary"
            size="small"
            :aria-label="toggleLabel"
            :aria-expanded="ariaExpandedAttr"
            :aria-controls="anchorId"
            class="btn-icon -gl-mr-2"
            data-testid="crud-collapse-toggle"
            @click="toggleCollapse"
          >
            <gl-animated-chevron-lg-down-up-icon :is-on="!isCollapsed" variant="default" />
          </gl-button>
        </div>
      </div>
    </header>

    <div
      v-if="isFormUsedAndVisible"
      class="gl-mx-4 gl-mb-4 gl-rounded-lg gl-bg-default gl-p-4 gl-shadow-sm"
      data-testid="crud-form"
    >
      <slot name="form" :hide-form="hideForm"></slot>
    </div>

    <template v-if="isContentVisible || keepAliveCollapsedContent">
      <div
        v-show="isContentVisible"
        class="crud-body gl-grow gl-rounded-lg gl-bg-default gl-p-3 contrast-more:gl-border forced-colors:gl-border"
        :class="[bodyClass, { 'gl-px-3 gl-pt-3': isLoading }]"
        data-testid="crud-body"
      >
        <gl-skeleton-loader v-if="isLoading" :width="400" :lines="3" data-testid="crud-loading" />

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
        v-show="isContentVisible"
        v-if="$scopedSlots.footer"
        class="gl-rounded-b-lg gl-px-3 gl-pb-2 gl-pt-3"
        :class="footerClass"
        data-testid="crud-footer"
      >
        <slot name="footer"></slot>
      </footer>
    </template>
  </component>
</template>
