<script>
import { GlIcon } from '@gitlab/ui';
import DurationBadge from './duration_badge.vue';
import LineNumber from './line_number.vue';

export default {
  components: {
    GlIcon,
    LineNumber,
    DurationBadge,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    isClosed: {
      type: Boolean,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    duration: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    iconName() {
      return this.isClosed ? 'angle-right' : 'angle-down';
    },
  },
  methods: {
    handleOnClick() {
      this.$emit('toggleLine');
    },
  },
};
</script>

<template>
  <div
    class="log-line collapsible-line d-flex justify-content-between ws-normal"
    role="button"
    @click="handleOnClick"
  >
    <gl-icon :name="iconName" class="arrow position-absolute" />
    <line-number :line-number="line.lineNumber" :path="path" />
    <span
      v-for="(content, i) in line.content"
      :key="i"
      class="line-text w-100 gl-white-space-pre-wrap"
      :class="content.style"
      >{{ content.text }}</span
    >
    <duration-badge v-if="duration" :duration="duration" />
  </div>
</template>
