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
    v-tooltip
    :title="__('Part of merge request changes')"
    :size="12"
    name="git-merge"
    css-classes="append-right-8"
  />
</template>
