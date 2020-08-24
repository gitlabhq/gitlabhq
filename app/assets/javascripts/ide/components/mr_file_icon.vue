<script>
import { GlIcon } from '@gitlab/ui';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    GlIcon,
  },
  directives: {
    tooltip,
  },
};
</script>

<template>
  <gl-icon
    v-tooltip
    :title="__('Part of merge request changes')"
    :size="12"
    name="git-merge"
    class="gl-mr-3"
  />
</template>
