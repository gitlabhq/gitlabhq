<script>
import { GlIcon } from '@gitlab/ui';

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
      hiddenSections: new Set(), // Use Set instead of Array. has() is more performant than includes() and it's executed more frequently
    };
  },
  methods: {
    isLineHidden(sections = []) {
      for (const s of sections) {
        if (this.hiddenSections.has(s)) {
          return true;
        }
      }
      return false;
    },
    toggleSection(section) {
      if (this.hiddenSections.has(section)) {
        this.hiddenSections.delete(section);
      } else {
        this.hiddenSections.add(section);
      }
      this.hiddenSections = new Set(this.hiddenSections); // `Set` is not reactive in Vue 2, create new instance it to trigger reactivity
    },
  },
};
</script>

<template>
  <div
    class="job-log-viewer gl-font-monospace gl-p-3 gl-font-sm gl-rounded-base"
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
          :name="hiddenSections.has(line.header) ? 'chevron-lg-right' : 'chevron-lg-down'"
        /><a :id="`L${index + 1}`" :href="`#L${index + 1}`" class="log-line-number" @click.stop>{{
          index + 1
        }}</a>
      </div>
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
