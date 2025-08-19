<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import CrudComponent from '~/vue_shared/components/crud_component.vue';

export default {
  components: {
    CrudComponent,
    GlIcon,
    GlLink,
  },
  props: {
    linkedResources: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <crud-component
    anchor-id="resources"
    :count="linkedResources.length"
    is-collapsible
    persist-collapsed-state
    :title="s__('WorkItem|Resources')"
  >
    <template #default>
      <span
        v-for="resource in linkedResources"
        :key="resource.url"
        class="gl-border gl-inline-flex gl-rounded-base gl-bg-default gl-px-3 gl-py-2"
      >
        <gl-link
          class="gl-inline-flex gl-items-center gl-gap-3 gl-font-semibold gl-text-default hover:gl-text-default focus:gl-text-default"
          :href="resource.url"
        >
          <gl-icon name="brand-zoom" />
          {{ s__('WorkItem|Zoom link') }}
        </gl-link>
      </span>
    </template>
  </crud-component>
</template>
