<script>
import { GlLink, GlBadge, GlSprintf } from '@gitlab/ui';

export default {
  name: 'IssuableStats',
  components: {
    GlLink,
    GlBadge,
    GlSprintf,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    total: {
      type: Number,
      required: true,
    },
    closed: {
      type: Number,
      required: true,
    },
    merged: {
      type: Number,
      required: false,
      default: null,
    },
    openedPath: {
      type: String,
      required: false,
      default: '',
    },
    closedPath: {
      type: String,
      required: false,
      default: '',
    },
    mergedPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    opened() {
      return this.total - (this.closed + (this.merged || 0));
    },
    showMerged() {
      return this.merged != null;
    },
  },
};
</script>

<template>
  <div class="gl-mb-5 gl-mr-6 gl-flex gl-shrink-0 gl-flex-col">
    <span class="gl-mb-2">
      {{ label }}
      <gl-badge variant="muted">{{ total }}</gl-badge>
    </span>
    <div class="gl-flex">
      <span class="gl-whitespace-pre-wrap" data-testid="open-stat">
        <gl-sprintf :message="__('Open: %{open}')">
          <template #open>
            <gl-link v-if="openedPath" :href="openedPath">{{ opened }}</gl-link>
            <template v-else>{{ opened }}</template>
          </template>
        </gl-sprintf>
      </span>

      <template v-if="showMerged">
        <span class="gl-mx-2">&bull;</span>

        <span class="gl-whitespace-pre-wrap" data-testid="merged-stat">
          <gl-sprintf :message="__('Merged: %{merged}')">
            <template #merged>
              <gl-link v-if="mergedPath" :href="mergedPath">{{ merged }}</gl-link>
              <template v-else>{{ merged }}</template>
            </template>
          </gl-sprintf>
        </span>
      </template>

      <span class="gl-mx-2">&bull;</span>

      <span class="gl-whitespace-pre-wrap" data-testid="closed-stat">
        <gl-sprintf :message="__('Closed: %{closed}')">
          <template #closed>
            <gl-link v-if="closedPath" :href="closedPath">{{ closed }}</gl-link>
            <template v-else>{{ closed }}</template>
          </template>
        </gl-sprintf>
      </span>
    </div>
  </div>
</template>
