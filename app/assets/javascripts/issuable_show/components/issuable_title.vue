<script>
import {
  GlIcon,
  GlButton,
  GlIntersectionObserver,
  GlTooltipDirective,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    editTitleAndDescription: __('Edit title and description'),
  },
  components: {
    GlIcon,
    GlButton,
    GlIntersectionObserver,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    issuable: {
      type: Object,
      required: true,
    },
    statusBadgeClass: {
      type: String,
      required: true,
    },
    statusIcon: {
      type: String,
      required: true,
    },
    enableEdit: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      stickyTitleVisible: false,
    };
  },
  methods: {
    handleTitleAppear() {
      this.stickyTitleVisible = false;
    },
    handleTitleDisappear() {
      this.stickyTitleVisible = true;
    },
  },
};
</script>

<template>
  <div>
    <div class="title-container">
      <h2 v-safe-html="issuable.titleHtml || issuable.title" class="title qa-title" dir="auto"></h2>
      <gl-button
        v-if="enableEdit"
        v-gl-tooltip.bottom
        :title="$options.i18n.editTitleAndDescription"
        :aria-label="$options.i18n.editTitleAndDescription"
        icon="pencil"
        class="btn-edit js-issuable-edit qa-edit-button"
        @click="$emit('edit-issuable', $event)"
      />
    </div>
    <gl-intersection-observer @appear="handleTitleAppear" @disappear="handleTitleDisappear">
      <transition name="issuable-header-slide">
        <div
          v-if="stickyTitleVisible"
          class="issue-sticky-header gl-fixed gl-z-index-3 gl-bg-white gl-border-1 gl-border-b-solid gl-border-b-gray-100 gl-py-3"
          data-testid="header"
        >
          <div
            class="issue-sticky-header-text gl-display-flex gl-align-items-center gl-mx-auto gl-px-5"
          >
            <p
              data-testid="status"
              class="issuable-status-box status-box gl-my-0"
              :class="statusBadgeClass"
            >
              <gl-icon :name="statusIcon" class="gl-display-block d-sm-none gl-h-6!" />
              <span class="gl-display-none d-sm-block"><slot name="status-badge"></slot></span>
            </p>
            <p
              class="gl-font-weight-bold gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis gl-my-0"
              :title="issuable.title"
            >
              {{ issuable.title }}
            </p>
          </div>
        </div>
      </transition>
    </gl-intersection-observer>
  </div>
</template>
