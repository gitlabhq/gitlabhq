<script>
import { GlIcon } from '@gitlab/ui';

import { STATUS_DONE, STATUS_TODO, STATUS_BLOCKED, STATUS_ERROR } from '../constants';

const STATUS_ICONS = {
  [STATUS_DONE]: { name: 'check-circle-filled', variant: 'success' },
  [STATUS_TODO]: { name: 'check-circle-dashed', variant: 'subtle' },
  [STATUS_BLOCKED]: { name: 'dash-circle', variant: 'disabled' },
  [STATUS_ERROR]: { name: 'error', variant: 'danger' },
};

/**
 * One line of the "Run GitLab Duo agents on this project" card: a status icon, a title and
 * description, and a control on the right. The control is a slot so the same row can carry a
 * setting toggle or an action button.
 */
export default {
  name: 'DuoReadinessRow',
  components: { GlIcon },
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    status: {
      type: String,
      required: true,
      validator: (value) => Object.keys(STATUS_ICONS).includes(value),
    },
    // Indents the row and tints it, for a setting that only qualifies the row above it.
    nested: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    icon() {
      return STATUS_ICONS[this.status];
    },
    isBlocked() {
      return this.status === STATUS_BLOCKED;
    },
  },
};
</script>

<template>
  <!-- The divider is dropped on the first row so it does not double up with the card border. -->
  <div
    class="gl-border-t gl-flex gl-items-center gl-gap-3 gl-py-3 gl-pr-4 first:gl-border-t-0"
    :class="nested ? 'gl-bg-subtle gl-pl-9' : 'gl-pl-4'"
    data-testid="readiness-row"
  >
    <gl-icon
      :name="icon.name"
      :variant="icon.variant"
      :size="16"
      class="gl-shrink-0"
      data-testid="readiness-row-icon"
    />

    <div class="gl-min-w-0 gl-grow">
      <div class="gl-flex gl-items-center">
        <span
          class="gl-font-bold"
          :class="{ 'gl-text-subtle': isBlocked }"
          data-testid="readiness-row-title"
        >
          {{ title }}
        </span>
        <slot name="title-icon"></slot>
      </div>
      <div class="gl-text-sm gl-text-subtle" data-testid="readiness-row-description">
        <slot name="description">{{ description }}</slot>
      </div>
    </div>

    <div class="gl-flex gl-shrink-0 gl-justify-end" data-testid="readiness-row-control">
      <slot></slot>
    </div>
  </div>
</template>
