<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlIcon },
  mixins: [timeagoMixin, glFeatureFlagMixin()],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    duration() {
      return this.pipeline?.details?.duration;
    },
    finishedTime() {
      return this.pipeline?.details?.finished_at;
    },
    durationFormatted() {
      const date = new Date(this.duration * 1000);

      let hh = date.getUTCHours();
      let mm = date.getUTCMinutes();
      let ss = date.getSeconds();

      // left pad
      if (hh < 10) {
        hh = `0${hh}`;
      }
      if (mm < 10) {
        mm = `0${mm}`;
      }
      if (ss < 10) {
        ss = `0${ss}`;
      }

      return `${hh}:${mm}:${ss}`;
    },
    legacySectionClass() {
      return !this.glFeatures.newPipelinesTable ? 'table-section section-15' : '';
    },
    legacyTableMobileClass() {
      return !this.glFeatures.newPipelinesTable ? 'table-mobile-content' : '';
    },
  },
};
</script>
<template>
  <div :class="legacySectionClass">
    <div v-if="!glFeatures.newPipelinesTable" class="table-mobile-header" role="rowheader">
      {{ s__('Pipeline|Duration') }}
    </div>
    <div :class="legacyTableMobileClass">
      <p v-if="duration" class="duration">
        <gl-icon name="timer" class="gl-vertical-align-baseline!" :size="12" />
        {{ durationFormatted }}
      </p>

      <p v-if="finishedTime" class="finished-at d-none d-md-block">
        <gl-icon name="calendar" class="gl-vertical-align-baseline!" :size="12" />

        <time
          v-gl-tooltip
          :title="tooltipTitle(finishedTime)"
          data-placement="top"
          data-container="body"
        >
          {{ timeFormatted(finishedTime) }}
        </time>
      </p>
    </div>
  </div>
</template>
