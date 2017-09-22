<script>
  import iconCycleAnalyticsSplash from 'icons/_icon_cycle_analytics_splash.svg';

  export default {
    name: 'cycleAnalyticsBanner',
    props: {
      helpPath: {
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
        this.$emit('dismissBanner');
      },
    },
  };
</script>
<template>
  <div class="landing content-block">
    <button
      type="button"
      class="dismiss-button"
      aria-label="Dismiss Cycle Analytics introduction box"
      @click="dismissOverviewDialog">
      <i
        class="fa fa-times"
        aria-hidden="true">
      </i>
    </button>
    <div
      class="svg-container"
      v-html="iconCycleAnalyticsSplash">
    </div>
    <div class="inner-content">
      <h4>
        {{ __('Introducing Cycle Analytics') }}
      </h4>
      <p>
        {{ __('Cycle Analytics gives an overview of how much time it takes to go from idea to production in your project.') }}
      </p>
      <p>
        <a href="this.helpPath" class="btn" target="_blank">
          {{ __('Read more')}}
        </a>
      </p>
    </div>
  </div>
</template>
