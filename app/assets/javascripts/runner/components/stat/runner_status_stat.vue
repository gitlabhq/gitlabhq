<script>
import { s__ } from '~/locale';
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '../../constants';
import RunnerSingleStat from './runner_single_stat.vue';

export default {
  components: {
    RunnerSingleStat,
  },
  props: {
    scope: {
      type: String,
      required: true,
    },
    variables: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    status: {
      type: String,
      required: true,
    },
  },
  computed: {
    countVariables() {
      return { ...this.variables, status: this.status };
    },
    skip() {
      // Status are mutually exclusive, skip displaying this total
      // when filtering by an status different to this one
      const { status } = this.variables;
      return status && status !== this.status;
    },
    statProps() {
      switch (this.status) {
        case STATUS_ONLINE:
          return {
            variant: 'success',
            title: s__('Runners|Online runners'),
            metaText: s__('Runners|online'),
          };
        case STATUS_OFFLINE:
          return {
            variant: 'muted',
            title: s__('Runners|Offline runners'),
            metaText: s__('Runners|offline'),
          };
        case STATUS_STALE:
          return {
            variant: 'warning',
            title: s__('Runners|Stale runners'),
            metaText: s__('Runners|stale'),
          };
        default:
          return {
            title: s__('Runners|Runners'),
          };
      }
    },
  },
};
</script>
<template>
  <runner-single-stat
    v-if="statProps"
    v-bind="statProps"
    :scope="scope"
    :variables="countVariables"
    :skip="skip"
  />
</template>
