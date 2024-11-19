<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import DrawerItem from '~/diffs/components/shared/findings_drawer_item.vue';
import { SAST_FINDING_DISMISSED } from '~/diffs/constants';

export default {
  name: 'FindingsDrawerDetails',
  DrawerItem,
  components: { DrawerItem, GlBadge, GlLink },
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
    findingsStatus() {
      return this.drawer.state === SAST_FINDING_DISMISSED ? 'muted' : 'warning';
    },
    isCodeQuality() {
      return this.drawer.scale === this.$options.codeQuality;
    },
  },
  methods: {
    concatIdentifierName(name, index) {
      return name + (index !== this.drawer.identifiers.length - 1 ? ', ' : '');
    },
  },
  i18n: {
    name: __('Name'),
    status: __('Status'),
    description: __('Description'),
    project: __('Project'),
    file: __('File'),
    identifiers: __('Identifiers'),
    tool: __('Tool'),
    codeQuality: s__('FindingsDrawer|Code Quality'),
    sast: __('SAST'),
    engine: __('Engine'),
  },
};
</script>

<template>
  <ul class="gl-mb-0 gl-list-none !gl-pb-0 gl-border-b-initial">
    <drawer-item
      v-if="drawer.title"
      :description="$options.i18n.name"
      :value="drawer.title"
      data-testid="findings-drawer-title"
    />

    <drawer-item v-if="drawer.state" :description="$options.i18n.status">
      <template #value>
        <gl-badge :variant="findingsStatus" class="text-capitalize">{{ drawer.state }}</gl-badge>
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
