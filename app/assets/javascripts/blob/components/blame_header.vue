<script>
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';
import BlameLegend from '~/blame/blame_legend.vue';

export default {
  components: { BlamePreferences, BlameLegend },
  inject: ['hasRevsFile'],
  data() {
    return {
      showAgeIndicator: false,
    };
  },
  methods: {
    onToggleAgeIndicator(value) {
      this.showAgeIndicator = value;
    },
  },
};
</script>
<template>
  <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-3">
    <blame-legend v-if="showAgeIndicator" />
    <blame-preferences :has-revs-file="hasRevsFile" @toggle-age-indicator="onToggleAgeIndicator" />
  </div>
</template>
