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
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      open: true,
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
  watch: {
    count(newVal) {
      this.open = newVal > 0;
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
  <div>
    <section class="gl-border gl-rounded-base">
      <header
        :class="{ 'gl-rounded-base': !open }"
        class="gl-rounded-tl-base gl-rounded-tr-base gl-bg-gray-10 gl-px-5 gl-py-4"
      >
        <h5 class="gl-m-0">
          <gl-button
            :icon="toggleButtonIcon"
            size="small"
            category="tertiary"
            class="gl-mr-2"
            :aria-label="toggleButtonLabel"
            :disabled="count === 0"
            data-testid="section-toggle-button"
            @click="toggleOpen"
          />
          {{ title }}
          <gl-badge v-if="!loading" class="gl-ml-1" variant="neutral" size="sm">{{
            count
          }}</gl-badge>
        </h5>
      </header>
      <div v-if="open" data-testid="section-content">
        <slot></slot>
      </div>
    </section>
    <slot v-if="open" name="pagination"></slot>
  </div>
</template>
