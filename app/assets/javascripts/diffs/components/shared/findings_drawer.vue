<script>
import { GlDrawer, GlButton, GlButtonGroup, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getSeverity } from '~/ci/reports/utils';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import FindingsDrawerDetails from '~/diffs/components/shared/findings_drawer_details.vue';

export const i18n = {
  codeQualityFinding: s__('FindingsDrawer|Code Quality Finding'),
  sastFinding: s__('FindingsDrawer|SAST Finding'),
  codeQuality: s__('FindingsDrawer|Code Quality'),
  detected: s__('FindingsDrawer|Detected in pipeline'),
  nextButton: s__('FindingsDrawer|Next finding'),
  previousButton: s__('FindingsDrawer|Previous finding'),
};
export const codeQuality = 'codeQuality';

export default {
  i18n,
  codeQuality,
  components: {
    FindingsDrawerDetails,
    GlDrawer,
    GlButton,
    GlButtonGroup,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    drawer: {
      type: Object,
      required: true,
    },
    project: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  data() {
    return {
      activeIndex: 0,
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    isCodeQuality() {
      return this.activeElement.scale === this.$options.codeQuality;
    },
    activeElement() {
      return this.drawer.findings[this.activeIndex];
    },
  },
  DRAWER_Z_INDEX,
  watch: {
    drawer(newVal) {
      this.activeIndex = newVal.index;
    },
  },
  methods: {
    getSeverity,
    prev() {
      if (this.activeIndex === 0) {
        this.activeIndex = this.drawer.findings.length - 1;
      } else {
        this.activeIndex -= 1;
      }
    },
    next() {
      if (this.activeIndex === this.drawer.findings.length - 1) {
        this.activeIndex = 0;
      } else {
        this.activeIndex += 1;
      }
    },
  },
};
</script>
<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    class="findings-drawer"
    :open="Object.keys(drawer).length !== 0"
    @close="$emit('close')"
  >
    <template #title>
      <h2 class="drawer-heading gl-mb-0 gl-mt-0 gl-w-28 gl-text-base">
        <gl-icon
          :size="12"
          :name="getSeverity(activeElement).name"
          :class="getSeverity(activeElement).class"
          class="inline-findings-severity-icon !gl-align-baseline"
        />
        <span class="drawer-heading-severity">{{ activeElement.severity }}</span>
        {{ isCodeQuality ? $options.i18n.codeQualityFinding : $options.i18n.sastFinding }}
      </h2>
      <div v-if="drawer.findings.length > 1">
        <gl-button-group>
          <gl-button
            v-gl-tooltip.bottom
            :title="$options.i18n.previousButton"
            :aria-label="$options.i18n.previousButton"
            size="small"
            data-testid="findings-drawer-prev-button"
            @click="prev"
          >
            <gl-icon
              :size="14"
              class="findings-drawer-nav-button gl-relative"
              name="chevron-lg-left"
            />
          </gl-button>
          <gl-button size="small" @click="next">
            <gl-icon
              v-gl-tooltip.bottom
              data-testid="findings-drawer-next-button"
              :title="$options.i18n.nextButton"
              :aria-label="$options.i18n.nextButton"
              class="findings-drawer-nav-button gl-relative"
              :size="14"
              name="chevron-lg-right"
            />
          </gl-button>
        </gl-button-group>
      </div>
    </template>

    <template #default>
      <findings-drawer-details :drawer="activeElement" :project="project" />
    </template>
  </gl-drawer>
</template>
