<script>
import { GlIcon, GlBadge, GlButton, GlIntersectionObserver, GlTooltipDirective } from '@gitlab/ui';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { STATUS_OPEN } from '~/issues/constants';
import { __ } from '~/locale';

export default {
  i18n: {
    editTitleAndDescription: __('Edit title and description'),
  },
  components: {
    GlIcon,
    GlBadge,
    GlButton,
    GlIntersectionObserver,
    ConfidentialityBadge,
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
    statusIcon: {
      type: String,
      required: true,
    },
    enableEdit: {
      type: Boolean,
      required: true,
    },
    hideEditButton: {
      type: Boolean,
      required: false,
    },
    workspaceType: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      stickyTitleVisible: false,
    };
  },
  computed: {
    badgeVariant() {
      return this.issuable.state === STATUS_OPEN ? 'success' : 'info';
    },
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
      <h1
        v-safe-html="issuable.titleHtml || issuable.title"
        class="title gl-font-size-h-display"
        dir="auto"
        data-testid="issuable-title"
      ></h1>
      <gl-button
        v-if="enableEdit && !hideEditButton"
        v-gl-tooltip.bottom
        :title="$options.i18n.editTitleAndDescription"
        :aria-label="$options.i18n.editTitleAndDescription"
        icon="pencil"
        class="btn-edit js-issuable-edit"
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
          <div class="issue-sticky-header-text gl-display-flex gl-align-items-baseline gl-mx-auto">
            <gl-badge
              class="gl-white-space-nowrap gl-mr-3 gl-align-self-center"
              :variant="badgeVariant"
            >
              <gl-icon v-if="statusIcon" class="gl-sm-display-none" :name="statusIcon" />
              <span class="gl-display-none gl-sm-display-block">
                <slot name="status-badge"></slot>
              </span>
            </gl-badge>
            <confidentiality-badge
              v-if="issuable.confidential"
              class="gl-white-space-nowrap gl-mr-3 gl-align-self-center"
              :issuable-type="issuable.type"
              :workspace-type="workspaceType"
            />
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
