<script>
import { GlButton, GlIcon, GlLoadingIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlIcon,
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
    bodyClass: {
      type: [String, Object],
      required: false,
      default: null,
    },
  },
  data() {
    return {
      collapsed: false,
      isFormVisible: false,
    };
  },
  computed: {
    isContentVisible() {
      const hasContent =
        this.$scopedSlots.default || this.$scopedSlots.empty || this.$scopedSlots.pagination;
      return !(hasContent && this.isCollapsible && this.collapsed);
    },
    toggleIcon() {
      return this.collapsed ? 'chevron-lg-down' : 'chevron-lg-up';
    },
    toggleLabel() {
      return this.collapsed ? __('Expand') : __('Collapse');
    },
    ariaExpandedAttr() {
      return this.collapsed ? 'false' : 'true';
    },
    displayedCount() {
      if (this.isLoading) {
        return '...';
      }

      return this.icon && !this.count ? '0' : this.count;
    },
    isFormUsedAndVisible() {
      return this.$scopedSlots.form && this.isFormVisible && !this.collapsed;
    },
  },
  methods: {
    toggleCollapse() {
      this.collapsed = !this.collapsed;
    },
    showForm() {
      this.isFormVisible = true;
      this.collapsed = false;
    },
    hideForm() {
      this.isFormVisible = false;
    },
    toggleForm() {
      if (this.isFormVisible) {
        this.hideForm();
      } else {
        this.showForm();
      }
    },
  },
};
</script>

<template>
  <section
    :id="anchorId"
    ref="crudComponent"
    class="crud gl-border gl-rounded-base gl-border-default gl-bg-subtle"
    :class="{ 'gl-mt-5': isCollapsible }"
  >
    <header
      class="gl-border-b gl-flex gl-flex-wrap gl-justify-between gl-gap-x-5 gl-gap-y-2 gl-rounded-t-base gl-border-default gl-bg-default gl-px-5 gl-py-4 gl-leading-24"
      :class="[headerClass, { 'gl-border-b-0 gl-rounded-base': !isContentVisible }]"
    >
      <div class="gl-flex gl-flex-col gl-self-center">
        <h2
          class="gl-m-0 gl-inline-flex gl-gap-3 gl-text-base gl-font-bold gl-leading-24"
          data-testid="crud-title"
        >
          <gl-link
            v-if="anchorId"
            class="anchor gl-absolute gl-no-underline"
            :href="`#${anchorId}`"
            :aria-labelledby="anchorId"
          />
          <slot v-if="$scopedSlots.title" name="title"></slot>
          <template v-else>{{ title }}</template>

          <span
            v-if="displayedCount || $scopedSlots.count"
            class="gl-inline-flex gl-items-center gl-gap-2 gl-text-sm gl-text-subtle"
            data-testid="crud-count"
          >
            <slot v-if="$scopedSlots.count" name="count"></slot>
            <template v-else>
              <gl-icon v-if="icon" :name="icon" data-testid="crud-icon" />
              {{ displayedCount }}
            </template>
          </span>
        </h2>
        <p
          v-if="description || $scopedSlots.description"
          class="gl-mb-0 gl-mt-1 gl-text-sm gl-text-subtle"
          data-testid="crud-description"
        >
          <slot v-if="$scopedSlots.description" name="description"></slot>
          <template v-else>{{ description }}</template>
        </p>
      </div>
      <div class="gl-flex gl-items-baseline gl-gap-3" data-testid="crud-actions">
        <slot name="actions"></slot>
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
          class="gl-border-l-1 gl-border-l-solid gl-border-default gl-pl-3 gl-h-6"
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
            class="gl-self-start -gl-mr-2"
            data-testid="crud-collapse-toggle"
            @click="toggleCollapse"
          />
        </div>
      </div>
    </header>

    <div
      v-if="isFormUsedAndVisible"
      class="gl-border-b gl-border-default gl-bg-default gl-p-5 gl-pt-4"
      data-testid="crud-form"
    >
      <slot name="form"></slot>
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
      <slot v-else></slot>

      <div
        v-if="$scopedSlots.pagination"
        class="crud-pagination gl-flex gl-justify-center gl-p-5 gl-border-t"
        data-testid="crud-pagination"
      >
        <slot name="pagination"></slot>
      </div>
    </div>

    <footer
      v-if="$scopedSlots.footer"
      class="gl-border-t gl-rounded-b-base gl-border-default gl-bg-default gl-px-5 gl-py-4"
      data-testid="crud-footer"
    >
      <slot name="footer"></slot>
    </footer>
  </section>
</template>
