<script>
import { GlButton, GlBadge } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlButton,
    GlBadge,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      open: this.count > 0,
    };
  },
  computed: {
    toggleButtonIcon() {
      return this.open ? 'chevron-down' : 'chevron-right';
    },
    toggleButtonLabel() {
      return sprintf(
        this.open
          ? __('Collapse %{section} merge requests')
          : __('Expand %{section} merge requests'),
        {
          section: this.title.toLowerCase(),
        },
      );
    },
  },
  methods: {
    toggleOpen() {
      this.open = !this.open;
    },
  },
};
</script>

<template>
  <section class="gl-bg-gray-50 gl-p-4 gl-rounded-base">
    <header class="gl-display-flex gl-align-items-center">
      <gl-button
        :icon="toggleButtonIcon"
        size="small"
        category="tertiary"
        class="gl-mr-3"
        :aria-label="toggleButtonLabel"
        data-testid="section-toggle-button"
        @click="toggleOpen"
      />
      <strong>{{ title }}</strong>
      <gl-badge class="gl-ml-3" variant="neutral" size="sm">{{ count }}</gl-badge>
    </header>
    <div v-if="open" class="gl-mt-3" data-testid="section-content">
      <slot></slot>
    </div>
  </section>
</template>
