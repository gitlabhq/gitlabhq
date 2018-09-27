<script>
import Ide from '~/ide/components/ide.vue';
import EERightPane from './panes/right.vue';

export default {
  name: 'EEIde',
  components: {
    Ide,
  },
  EERightPane,
};
</script>

<template>
  <ide
    :right-pane-component="$options.EERightPane"
  />
</template>
