<script>
import { GlIcon } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';

export default {
  name: 'LogViewer',
  components: {
    GlIcon,
  },
  props: {
    log: {
      type: Array,
      default: () => [],
      required: false,
    },
    loading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      collapsedSections: new Set(), // Use Set instead of Array. has() is more performant than includes() and it's executed more frequently
    };
  },
  watch: {
    log: {
      immediate: true,
      handler() {
        // Reset the currently collapsed sections when log is loaded
        const collapsed = this.log
          .filter(({ options }) => parseBoolean(options?.collapsed))
          .map(({ header }) => header);

        this.collapsedSections = new Set(collapsed);
      },
    },
  },
  methods: {
    isLineHidden(sections = []) {
      for (const s of sections) {
        if (this.collapsedSections.has(s)) {
          return true;
        }
      }
      return false;
    },
    toggleSection(section) {
      if (this.collapsedSections.has(section)) {
        this.collapsedSections.delete(section);
      } else {
        this.collapsedSections.add(section);
      }
      this.collapsedSections = new Set(this.collapsedSections); // `Set` is not reactive in Vue 2, create new instance it to trigger reactivity
    },
    parseTime(rawTime) {
      const DATE_PLUS_T_LENGTH = 11; // 2024-05-30T
      const TIME_LENGTH = 8; // 00:00:00
      return `${rawTime.slice(DATE_PLUS_T_LENGTH, DATE_PLUS_T_LENGTH + TIME_LENGTH)}`;
    },
  },
};
</script>

<template>
  <div
    class="job-log-viewer gl-rounded-bl-base gl-rounded-br-base gl-p-3 gl-text-sm gl-font-monospace"
    role="log"
    aria-live="polite"
    :aria-busy="loading"
  >
    <div
      v-for="(line, index) in log"
      v-show="!isLineHidden(line.sections)"
      :key="index"
      class="log-line"
      :class="{ 'log-line-header': line.header }"
      v-on="line.header ? { click: () => toggleSection(line.header) } : {}"
    >
      <div>
        <gl-icon
          v-if="line.header"
          :name="collapsedSections.has(line.header) ? 'chevron-lg-right' : 'chevron-lg-down'"
        /><a :id="`L${index + 1}`" :href="`#L${index + 1}`" class="log-line-number" @click.stop>{{
          index + 1
        }}</a>
      </div>
      <time v-if="line.timestamp" :datetime="line.timestamp">{{ parseTime(line.timestamp) }}</time>
      <div>
        <span v-for="(c, j) in line.content" :key="j" :class="c.style">{{ c.text }}</span>
      </div>
    </div>
    <div v-if="loading" class="loader-animation gl-p-3">
      <span class="gl-sr-only">{{ __('Loading...') }}</span>
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </div>
</template>
