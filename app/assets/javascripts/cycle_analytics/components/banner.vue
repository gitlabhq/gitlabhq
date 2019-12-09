<script>
import iconCycleAnalyticsSplash from 'icons/_icon_cycle_analytics_splash.svg';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    documentationLink: {
      type: String,
      required: true,
    },
  },
  computed: {
    iconCycleAnalyticsSplash() {
      return iconCycleAnalyticsSplash;
    },
  },
  methods: {
    dismissOverviewDialog() {
      this.$emit('dismiss-overview-dialog');
    },
  },
};
</script>
<template>
  <div class="landing content-block">
    <button
      :aria-label="__('Dismiss Cycle Analytics introduction box')"
      class="js-ca-dismiss-button dismiss-button"
      type="button"
      @click="dismissOverviewDialog"
    >
      <icon name="close" />
    </button>
    <div class="svg-container" v-html="iconCycleAnalyticsSplash"></div>
    <div class="inner-content">
      <h4>{{ __('Introducing Cycle Analytics') }}</h4>
      <p>
        {{
          __(`Cycle Analytics gives an overview
of how much time it takes to go from idea to production in your project.`)
        }}
      </p>
      <p>
        <a :href="documentationLink" target="_blank" rel="nofollow" class="btn">
          {{ __('Read more') }}
        </a>
      </p>
    </div>
  </div>
</template>
