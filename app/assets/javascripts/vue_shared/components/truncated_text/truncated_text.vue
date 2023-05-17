<script>
import { GlResizeObserverDirective, GlButton } from '@gitlab/ui';
import { STATES, SHOW_MORE, SHOW_LESS } from './constants';

export default {
  name: 'TruncatedText',
  components: {
    GlButton,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    lines: {
      type: Number,
      required: false,
      default: 3,
    },
    mobileLines: {
      type: Number,
      required: false,
      default: 10,
    },
  },
  data() {
    return {
      state: STATES.INITIAL,
    };
  },
  computed: {
    showTruncationToggle() {
      return this.state !== STATES.INITIAL;
    },
    truncationToggleText() {
      if (this.state === STATES.TRUNCATED) {
        return SHOW_MORE;
      }
      return SHOW_LESS;
    },
    styleObject() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return { '--lines': this.lines, '--mobile-lines': this.mobileLines };
    },
    isTruncated() {
      return this.state === STATES.EXTENDED ? null : 'gl-truncate-text-by-line gl-overflow-hidden';
    },
  },
  methods: {
    onResize({ target }) {
      if (target.scrollHeight > target.offsetHeight) {
        this.state = STATES.TRUNCATED;
      } else if (this.state === STATES.TRUNCATED) {
        this.state = STATES.INITIAL;
      }
    },
    toggleTruncation() {
      if (this.state === STATES.TRUNCATED) {
        this.state = STATES.EXTENDED;
      } else if (this.state === STATES.EXTENDED) {
        this.state = STATES.TRUNCATED;
      }
    },
  },
};
</script>

<template>
  <section>
    <article
      ref="content"
      v-gl-resize-observer="onResize"
      :class="isTruncated"
      :style="styleObject"
    >
      <slot></slot>
    </article>
    <gl-button v-if="showTruncationToggle" variant="link" @click="toggleTruncation">{{
      truncationToggleText
    }}</gl-button>
  </section>
</template>
