<script>
  import { s__, sprintf } from '~/locale';
  import { dateInWords } from '~/lib/utils/datetime_utility';
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    props: {
      epic: {
        type: Object,
        required: true,
      },
      currentGroupId: {
        type: Number,
        required: true,
      },
    },
    computed: {
      isEpicGroupDifferent() {
        return this.currentGroupId !== this.epic.groupId;
      },
      /**
       * In case Epic start date is out of range
       * we need to use original date instead of proxy date
       */
      startDate() {
        if (this.epic.startDateOutOfRange) {
          return this.epic.originalStartDate;
        }

        return this.epic.startDate;
      },
      /**
       * In case Epic end date is out of range
       * we need to use original date instead of proxy date
       */
      endDate() {
        if (this.epic.endDateOutOfRange) {
          return this.epic.originalEndDate;
        }
        return this.epic.endDate;
      },
      /**
       * Compose timeframe string to show on UI
       * based on start and end date availability
       */
      timeframeString() {
        if (this.epic.startDateUndefined) {
          return sprintf(s__('GroupRoadmap|Until %{dateWord}'), {
            dateWord: dateInWords(this.endDate, true),
          });
        } else if (this.epic.endDateUndefined) {
          return sprintf(s__('GroupRoadmap|From %{dateWord}'), {
            dateWord: dateInWords(this.startDate, true),
          });
        }

        // In case both start and end date fall in same year
        // We should hide year from start date
        const startDateInWords = dateInWords(
          this.startDate,
          true,
          this.startDate.getFullYear() === this.endDate.getFullYear(),
        );

        return `${startDateInWords} &ndash; ${dateInWords(this.endDate, true)}`;
      },
    },
  };
</script>

<template>
  <span class="epic-details-cell">
    <div class="epic-title">
      <a
        v-tooltip
        data-container="body"
        class="epic-url"
        :href="epic.webUrl"
        :title="epic.title"
      >
        {{ epic.title }}
      </a>
    </div>
    <div class="epic-group-timeframe">
      <span
        v-tooltip
        v-if="isEpicGroupDifferent"
        class="epic-group"
        data-placement="right"
        data-container="body"
        :title="epic.groupFullName"
      >
        {{ epic.groupName }} &middot;
      </span>
      <span
        class="epic-timeframe"
        v-html="timeframeString"
      >
      </span>
    </div>
  </span>
</template>
