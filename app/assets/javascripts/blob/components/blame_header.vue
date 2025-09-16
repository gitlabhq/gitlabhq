<script>
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';
import BlameLegend from '~/blame/blame_legend.vue';

export default {
  components: { BlamePreferences, BlameLegend },
  inject: ['hasRevsFile'],
};
</script>
<template>
  <div class="gl-border-b gl-flex gl-justify-between gl-bg-subtle">
    <blame-legend />
    <blame-preferences :has-revs-file="hasRevsFile" />
  </div>
</template>
