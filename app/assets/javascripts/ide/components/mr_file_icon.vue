<script>
import icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    icon,
  },
  directives: {
    tooltip,
  },
};
</script>

<template>
  <icon
    name="git-merge"
    v-tooltip
    title="__('Part of merge request changes')"
    css-classes="ide-file-changed-icon"
    :size="12"
  />
</template>
