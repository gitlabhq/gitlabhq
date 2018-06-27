<script>
import TrackLine from './track_line.vue';
import TrackInfo from './track_info.vue';

export default {
  components: {
    TrackLine,
    TrackInfo,
  },
  props: {
    legendTitle: {
      type: String,
      required: true,
    },
    timeSeries: {
      type: Array,
      required: true,
    },
  },
  methods: {
    isStable(track) {
      return {
        'prometheus-table-row-highlight': track.trackName !== 'Canary' && track.renderCanary,
      };
    },
  },
};
</script>
<template>
  <div class="prometheus-graph-legends prepend-left-10">
    <table class="prometheus-table">
      <tr
        v-for="(series, index) in timeSeries"
        v-if="series.shouldRenderLegend"
        :key="index"
        :class="isStable(series)"
      >
        <td>
          <strong v-if="series.renderCanary">{{ series.trackName }}</strong>
        </td>
        <track-line :track="series" />
        <td
          v-if="timeSeries.length > 1"
          class="legend-metric-title">
          <track-info
            v-if="series.metricTag"
            :track="series" />
          <track-info
            v-else
            :track="series">
            <strong>{{ legendTitle }}</strong> series {{ index + 1 }}
          </track-info>
        </td>
        <td v-else>
          <track-info :track="series">
            <strong>{{ legendTitle }}</strong>
          </track-info>
        </td>
        <template v-for="(track, trackIndex) in series.tracksLegend">
          <track-line
            :track="track"
            :key="`track-line-${trackIndex}`"/>
          <td :key="`track-info-${trackIndex}`">
            <track-info
              :track="track"
              class="legend-metric-title" />
          </td>
        </template>
      </tr>
    </table>
  </div>
</template>
