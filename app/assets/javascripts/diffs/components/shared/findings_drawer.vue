<script>
import {
  GlBadge,
  GlDrawer,
  GlLink,
  GlButton,
  GlButtonGroup,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getSeverity } from '~/ci/reports/utils';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { SAST_FINDING_DISMISSED } from '../../constants';
import DrawerItem from './findings_drawer_item.vue';

export const i18n = {
  name: __('Name'),
  description: __('Description'),
  status: __('Status'),
  sast: __('SAST'),
  engine: __('Engine'),
  identifiers: __('Identifiers'),
  project: __('Project'),
  file: __('File'),
  tool: __('Tool'),
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
  components: { GlBadge, GlDrawer, GlLink, GlButton, GlButtonGroup, GlIcon, DrawerItem },
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
    findingsStatus() {
      return this.activeElement.state === SAST_FINDING_DISMISSED ? 'muted' : 'warning';
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

    concatIdentifierName(name, index) {
      return name + (index !== this.activeElement.identifiers.length - 1 ? ', ' : '');
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
      <h2 class="drawer-heading gl-font-base gl-mt-0 gl-mb-0 gl-w-28">
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
              class="gl-relative findings-drawer-nav-button"
              name="chevron-lg-left"
            />
          </gl-button>
          <gl-button size="small" @click="next">
            <gl-icon
              v-gl-tooltip.bottom
              data-testid="findings-drawer-next-button"
              :title="$options.i18n.nextButton"
              :aria-label="$options.i18n.nextButton"
              class="gl-relative findings-drawer-nav-button"
              :size="14"
              name="chevron-lg-right"
            />
          </gl-button>
        </gl-button-group>
      </div>
    </template>

    <template #default>
      <ul class="gl-list-none gl-border-b-initial gl-mb-0 gl-pb-0!">
        <drawer-item
          v-if="activeElement.title"
          :description="$options.i18n.name"
          :value="activeElement.title"
          data-testid="findings-drawer-title"
        />

        <drawer-item v-if="activeElement.state" :description="$options.i18n.status">
          <template #value>
            <gl-badge :variant="findingsStatus" class="text-capitalize">{{
              activeElement.state
            }}</gl-badge>
          </template>
        </drawer-item>

        <drawer-item
          v-if="activeElement.description"
          :description="$options.i18n.description"
          :value="activeElement.description"
        />

        <drawer-item
          v-if="project && activeElement.scale !== $options.codeQuality"
          :description="$options.i18n.project"
        >
          <template #value>
            <gl-link :href="`/${project.fullPath}`">{{ project.nameWithNamespace }}</gl-link>
          </template>
        </drawer-item>

        <drawer-item
          v-if="activeElement.location || activeElement.webUrl"
          :description="$options.i18n.file"
        >
          <template #value>
            <span v-if="activeElement.webUrl && activeElement.filePath && activeElement.line">
              <gl-link :href="activeElement.webUrl"
                >{{ activeElement.filePath }}:{{ activeElement.line }}</gl-link
              >
            </span>
            <span v-else-if="activeElement.location">
              {{ activeElement.location.file }}:{{ activeElement.location.startLine }}
            </span>
          </template>
        </drawer-item>

        <drawer-item
          v-if="activeElement.identifiers && activeElement.identifiers.length"
          :description="$options.i18n.identifiers"
        >
          <template #value>
            <span
              v-for="(identifier, index) in activeElement.identifiers"
              :key="identifier.externalId"
            >
              <gl-link v-if="identifier.url" :href="identifier.url">
                {{ concatIdentifierName(identifier.name, index) }}
              </gl-link>
              <span v-else>
                {{ concatIdentifierName(identifier.name, index) }}
              </span>
            </span>
          </template>
        </drawer-item>

        <drawer-item
          v-if="activeElement.scale"
          :description="$options.i18n.tool"
          :value="isCodeQuality ? $options.i18n.codeQuality : $options.i18n.sast"
        />

        <drawer-item
          v-if="activeElement.engineName"
          :description="$options.i18n.engine"
          :value="activeElement.engineName"
        />
      </ul>
    </template>
  </gl-drawer>
</template>
