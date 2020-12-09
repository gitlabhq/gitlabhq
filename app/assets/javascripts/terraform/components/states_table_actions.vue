<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    state: {
      required: true,
      type: Object,
    },
  },
  i18n: {
    downloadJSON: s__('Terraform|Download JSON'),
  },
};
</script>

<template>
  <div v-if="state.latestVersion">
    <gl-dropdown icon="ellipsis_v" right :data-testid="`terraform-state-actions-${state.name}`">
      <gl-dropdown-item
        data-testid="terraform-state-download"
        :download="`${state.name}.json`"
        :href="state.latestVersion.downloadPath"
      >
        {{ $options.i18n.downloadJSON }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
