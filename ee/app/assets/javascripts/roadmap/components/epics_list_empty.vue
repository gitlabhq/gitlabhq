<script>
  import { s__, sprintf } from '~/locale';
  import { dateInWords } from '~/lib/utils/datetime_utility';

  import NewEpic from '../../epics/new_epic/components/new_epic.vue';

  export default {
    components: {
      NewEpic,
    },
    props: {
      timeframeStart: {
        type: Date,
        required: true,
      },
      timeframeEnd: {
        type: Date,
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
        if (this.hasFiltersApplied) {
          return s__('GroupRoadmap|Sorry, no epics matched your search');
        }
        return s__('GroupRoadmap|The roadmap shows the progress of your epics along a timeline');
      },
      subMessage() {
        if (this.hasFiltersApplied) {
          return sprintf(s__('GroupRoadmap|To widen your search, change or remove filters. Only epics in the past 3 months and the next 3 months are shown &ndash; from %{startDate} to %{endDate}.'), {
            startDate: this.timeframeRange.startDate,
            endDate: this.timeframeRange.endDate,
          });
        }
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
        <new-epic
          v-if="!hasFiltersApplied"
          :endpoint="newEpicEndpoint"
        />
        <a
          class="btn btn-default"
          :title="__('List')"
          :href="newEpicEndpoint"
        >
          <span>{{ s__('View epics list') }}</span>
        </a>
      </div>
    </div>
  </div>
</template>
