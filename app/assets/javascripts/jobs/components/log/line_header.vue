<script>
import { GlIcon } from '@gitlab/ui';
import { getLocationHash } from '~/lib/utils/url_utility';
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
    isHighlighted: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      applyHashHighlight: false,
    };
  },
  computed: {
    iconName() {
      return this.isClosed ? 'chevron-lg-right' : 'chevron-lg-down';
    },
  },
  mounted() {
    const hash = getLocationHash();
    const lineToMatch = `L${this.line.lineNumber + 1}`;

    if (hash === lineToMatch) {
      this.applyHashHighlight = true;
    }
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
    class="log-line collapsible-line d-flex justify-content-between ws-normal gl-align-items-flex-start"
    :class="{ 'gl-bg-gray-700': isHighlighted || applyHashHighlight }"
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
