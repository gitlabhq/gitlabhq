<script>
import { s__, sprintf } from '~/locale';
import { dateInWords } from '~/lib/utils/datetime_utility';

import { PRESET_TYPES, PRESET_DEFAULTS } from '../constants';

import NewEpic from '../../epics/new_epic/components/new_epic.vue';

export default {
  components: {
    NewEpic,
  },
  props: {
    presetType: {
      type: String,
      required: true,
    },
    timeframeStart: {
      type: [Date, Object],
      required: true,
    },
    timeframeEnd: {
      type: [Date, Object],
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
      let startDate;
      let endDate;

      if (this.presetType === PRESET_TYPES.QUARTERS) {
        const quarterStart = this.timeframeStart.range[0];
        const quarterEnd = this.timeframeEnd.range[2];
        startDate = dateInWords(
          quarterStart,
          true,
          quarterStart.getFullYear() === quarterEnd.getFullYear(),
        );
        endDate = dateInWords(quarterEnd, true);
      } else if (this.presetType === PRESET_TYPES.MONTHS) {
        startDate = dateInWords(
          this.timeframeStart,
          true,
          this.timeframeStart.getFullYear() === this.timeframeEnd.getFullYear(),
        );
        endDate = dateInWords(this.timeframeEnd, true);
      } else if (this.presetType === PRESET_TYPES.WEEKS) {
        const end = new Date(this.timeframeEnd.getTime());
        end.setDate(end.getDate() + 6);

        startDate = dateInWords(
          this.timeframeStart,
          true,
          this.timeframeStart.getFullYear() === end.getFullYear(),
        );
        endDate = dateInWords(end, true);
      }

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
        return sprintf(PRESET_DEFAULTS[this.presetType].emptyStateWithFilters, {
          startDate: this.timeframeRange.startDate,
          endDate: this.timeframeRange.endDate,
        });
      }
      return sprintf(PRESET_DEFAULTS[this.presetType].emptyStateDefault, {
        startDate: this.timeframeRange.startDate,
        endDate: this.timeframeRange.endDate,
      });
    },
  },
};
</script>

<template>
  <div class="row empty-state">
    <div class="col-12">
      <div class="svg-content">
        <img
          :src="emptyStateIllustrationPath"
        />
      </div>
    </div>
    <div class="col-12">
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
