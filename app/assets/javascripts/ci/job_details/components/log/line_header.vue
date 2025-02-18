<script>
import { GlIcon } from '@gitlab/ui';
import { getLocationHash } from '~/lib/utils/url_utility';
import DurationBadge from './duration_badge.vue';
import LineNumber from './line_number.vue';

export default {
  name: 'LineHeader',
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
      required: false,
      default: false,
    },
    path: {
      type: String,
      required: true,
    },
    hideDuration: {
      type: Boolean,
      required: false,
      default: false,
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
    const lineToMatch = `L${this.line.lineNumber}`;

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
    class="js-log-line job-log-line-header job-log-line"
    :class="{ 'job-log-line-highlight': isHighlighted || applyHashHighlight }"
    role="button"
    @click="handleOnClick"
  >
    <gl-icon :name="iconName" class="arrow gl-absolute gl-top-2" />
    <line-number :line-number="line.lineNumber" :path="path" />
    <span v-if="line.time" class="job-log-time">{{ line.time }}</span>
    <span class="job-log-line-content">
      <span v-for="(content, i) in line.content" :key="i" :class="content.style">{{
        content.text
      }}</span>
    </span>
    <duration-badge v-if="duration && !hideDuration" :duration="duration" />
  </div>
</template>
