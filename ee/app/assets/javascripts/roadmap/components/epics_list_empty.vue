<script>
  import { s__, sprintf } from '~/locale';
  import { dateInWords } from '~/lib/utils/datetime_utility';

  export default {
    props: {
      timeframeStart: {
        type: Date,
        required: true,
      },
      timeframeEnd: {
        type: Date,
        required: true,
      },
      emptyStateIllustrationPath: {
        type: String,
        required: true,
      },
    },
    computed: {
      timeframeRange() {
        const startDate = dateInWords(
          this.timeframeStart,
          true,
          this.timeframeStart.getFullYear() === this.timeframeEnd.getFullYear(),
        );
        const endDate = dateInWords(this.timeframeEnd, true);

        return {
          startDate,
          endDate,
        };
      },
      message() {
        return s__('GroupRoadmap|Epics let you manage your portfolio of projects more efficiently and with less effort');
      },
      subMessage() {
        return sprintf(s__('GroupRoadmap|To view the roadmap, add a planned start or finish date to one of your epics in this group or its subgroups. Only epics in the past 3 months and the next 3 months are shown &ndash; from %{startDate} to %{endDate}.'), {
          startDate: this.timeframeRange.startDate,
          endDate: this.timeframeRange.endDate,
        });
      },
    },
  };
</script>

<template>
  <div class="row empty-state">
    <div class="col-xs-12">
      <div class="svg-content">
        <img
          :src="emptyStateIllustrationPath"
        />
      </div>
    </div>
    <div class="col-xs-12">
      <div class="text-content">
        <h4>{{ message }}</h4>
        <p v-html="subMessage"></p>
      </div>
    </div>
  </div>
</template>
