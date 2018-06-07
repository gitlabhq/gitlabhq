<script>
  import _ from 'underscore';
  import Flash from '~/flash';
  import { s__ } from '~/locale';
  import loadingIcon from '~/vue_shared/components/loading_icon.vue';

  import epicsListEmpty from './epics_list_empty.vue';
  import roadmapShell from './roadmap_shell.vue';

  export default {
    components: {
      loadingIcon,
      epicsListEmpty,
      roadmapShell,
    },
    props: {
      store: {
        type: Object,
        required: true,
      },
      service: {
        type: Object,
        required: true,
      },
      presetType: {
        type: String,
        required: true,
      },
      hasFiltersApplied: {
        type: Boolean,
        required: true,
      },
      newEpicEndpoint: {
        type: String,
        required: true,
      },
      emptyStateIllustrationPath: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        isLoading: true,
        isEpicsListEmpty: false,
        hasError: false,
        handleResizeThrottled: {},
      };
    },
    computed: {
      epics() {
        return this.store.getEpics();
      },
      timeframe() {
        return this.store.getTimeframe();
      },
      timeframeStart() {
        return this.timeframe[0];
      },
      timeframeEnd() {
        const last = this.timeframe.length - 1;
        return this.timeframe[last];
      },
      currentGroupId() {
        return this.store.getCurrentGroupId();
      },
      showRoadmap() {
        return !this.hasError && !this.isLoading && !this.isEpicsListEmpty;
      },
    },
    mounted() {
      this.fetchEpics();
      this.handleResizeThrottled = _.throttle(this.handleResize, 600);
      window.addEventListener('resize', this.handleResizeThrottled, false);
    },
    beforeDestroy() {
      window.removeEventListener('resize', this.handleResizeThrottled, false);
    },
    methods: {
      fetchEpics() {
        this.hasError = false;
        this.service.getEpics()
          .then(res => res.data)
          .then((epics) => {
            this.isLoading = false;
            if (epics.length) {
              this.store.setEpics(epics);
            } else {
              this.isEpicsListEmpty = true;
            }
          })
          .catch(() => {
            this.isLoading = false;
            this.hasError = true;
            Flash(s__('GroupRoadmap|Something went wrong while fetching epics'));
          });
      },
      /**
       * Roadmap view works with absolute sizing and positioning
       * of following child components of RoadmapShell;
       *
       * - RoadmapTimelineSection
       * - TimelineTodayIndicator
       * - EpicItemTimeline
       *
       * And hence when window is resized, any size attributes passed
       * down to child components are no longer valid, so best approach
       * to refresh entire app is to re-render it on resize, hence
       * we toggle `isLoading` variable which is bound to `RoadmapShell`.
       */
      handleResize() {
        this.isLoading = true;
        // We need to debounce the toggle to make sure loading animation
        // shows up while app is being rerendered.
        _.debounce(() => {
          this.isLoading = false;
        }, 200)();
      },
    },
  };
</script>

<template>
  <div
    class="roadmap-container"
    :class="{ 'overflow-reset': isEpicsListEmpty }"
  >
    <loading-icon
      class="loading-animation prepend-top-20 append-bottom-20"
      size="2"
      v-if="isLoading"
      :label="s__('GroupRoadmap|Loading roadmap')"
    />
    <roadmap-shell
      v-if="showRoadmap"
      :preset-type="presetType"
      :epics="epics"
      :timeframe="timeframe"
      :current-group-id="currentGroupId"
    />
    <epics-list-empty
      v-if="isEpicsListEmpty"
      :preset-type="presetType"
      :timeframe-start="timeframeStart"
      :timeframe-end="timeframeEnd"
      :has-filters-applied="hasFiltersApplied"
      :new-epic-endpoint="newEpicEndpoint"
      :empty-state-illustration-path="emptyStateIllustrationPath"
    />
  </div>
</template>
