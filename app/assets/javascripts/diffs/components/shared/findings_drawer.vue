<script>
import { GlBadge, GlDrawer, GlIcon, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getSeverity } from '~/ci/reports/utils';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
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
};
export const codeQuality = 'codeQuality';

export default {
  i18n,
  codeQuality,
  components: { GlBadge, GlDrawer, GlIcon, GlLink, DrawerItem },
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
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    isCodeQuality() {
      return this.drawer.scale === this.$options.codeQuality;
    },
  },
  DRAWER_Z_INDEX,
  methods: {
    getSeverity,
    concatIdentifierName(name, index) {
      return name + (index !== this.drawer.identifiers.length - 1 ? ', ' : '');
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
      <h2 class="drawer-heading gl-font-base gl-mt-0 gl-mb-0">
        <gl-icon
          :size="12"
          :name="getSeverity(drawer).name"
          :class="getSeverity(drawer).class"
          class="inline-findings-severity-icon gl-vertical-align-baseline!"
        />
        <span class="drawer-heading-severity">{{ drawer.severity }}</span>
        {{ isCodeQuality ? $options.i18n.codeQualityFinding : $options.i18n.sastFinding }}
      </h2>
    </template>

    <template #default>
      <ul class="gl-list-style-none gl-border-b-initial gl-mb-0 gl-pb-0!">
        <drawer-item v-if="drawer.title" :description="$options.i18n.name" :value="drawer.title" />

        <drawer-item v-if="drawer.state" :description="$options.i18n.status">
          <template #value>
            <gl-badge variant="warning" class="text-capitalize">{{ drawer.state }}</gl-badge>
          </template>
        </drawer-item>

        <drawer-item
          v-if="drawer.description"
          :description="$options.i18n.description"
          :value="drawer.description"
        />

        <drawer-item
          v-if="project && drawer.scale !== $options.codeQuality"
          :description="$options.i18n.project"
        >
          <template #value>
            <gl-link :href="`/${project.fullPath}`">{{ project.nameWithNamespace }}</gl-link>
          </template>
        </drawer-item>

        <drawer-item v-if="drawer.location || drawer.webUrl" :description="$options.i18n.file">
          <template #value>
            <span v-if="drawer.webUrl && drawer.filePath && drawer.line">
              <gl-link :href="drawer.webUrl">{{ drawer.filePath }}:{{ drawer.line }}</gl-link>
            </span>
            <span v-else-if="drawer.location">
              {{ drawer.location.file }}:{{ drawer.location.startLine }}
            </span>
          </template>
        </drawer-item>

        <drawer-item
          v-if="drawer.identifiers && drawer.identifiers.length"
          :description="$options.i18n.identifiers"
        >
          <template #value>
            <span v-for="(identifier, index) in drawer.identifiers" :key="identifier.externalId">
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
          v-if="drawer.scale"
          :description="$options.i18n.tool"
          :value="isCodeQuality ? $options.i18n.codeQuality : $options.i18n.sast"
        />

        <drawer-item
          v-if="drawer.engineName"
          :description="$options.i18n.engine"
          :value="drawer.engineName"
        />
      </ul>
    </template>
  </gl-drawer>
</template>
