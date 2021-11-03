<script>
import { GlCollapse, GlIcon, GlBadge, GlLink } from '@gitlab/ui';
import folderQuery from '../graphql/queries/folder.query.graphql';

export default {
  components: {
    GlCollapse,
    GlIcon,
    GlBadge,
    GlLink,
  },
  props: {
    nestedEnvironment: {
      type: Object,
      required: true,
    },
  },
  data() {
    return { visible: false };
  },
  apollo: {
    folder: {
      query: folderQuery,
      variables() {
        return { environment: this.nestedEnvironment.latest };
      },
    },
  },
  computed: {
    icons() {
      return this.visible
        ? { caret: 'angle-down', folder: 'folder-open' }
        : { caret: 'angle-right', folder: 'folder-o' };
    },
    count() {
      return this.folder?.availableCount ?? 0;
    },
    folderClass() {
      return { 'gl-font-weight-bold': this.visible };
    },
    folderPath() {
      return this.nestedEnvironment.latest.folderPath;
    },
  },
  methods: {
    toggleCollapse() {
      this.visible = !this.visible;
    },
  },
};
</script>
<template>
  <div class="gl-border-b-solid gl-border-gray-100 gl-border-1 gl-px-3 gl-pt-3 gl-pb-5">
    <div class="gl-w-full gl-display-flex gl-align-items-center" @click="toggleCollapse">
      <gl-icon
        class="gl-mr-2 gl-fill-current-color gl-text-gray-500"
        :name="icons.caret"
        :size="12"
      />
      <gl-icon class="gl-mr-2 gl-fill-current-color gl-text-gray-500" :name="icons.folder" />
      <div class="gl-mr-2 gl-text-gray-500" :class="folderClass">
        {{ nestedEnvironment.name }}
      </div>
      <gl-badge size="sm" class="gl-mr-auto">{{ count }}</gl-badge>
      <gl-link v-if="visible" :href="folderPath">{{ s__('Environments|Show all') }}</gl-link>
    </div>
    <gl-collapse :visible="visible" />
  </div>
</template>
