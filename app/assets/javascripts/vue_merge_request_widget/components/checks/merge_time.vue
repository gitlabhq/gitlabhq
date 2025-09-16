<script>
import { s__, sprintf } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import StatusIcon from '../widget/status_icon.vue';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import mergeTimeQuery from '../../queries/states/merge_time.query.graphql';
import { ICON_NAMES } from './constants';

const dateFormatter = localeDateFormat.asDateTime;

export default {
  name: 'MergeChecksMergeTime',
  apollo: {
    state: {
      query: mergeTimeQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest || {},
    },
  },
  components: {
    StatusIcon,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  props: {
    check: {
      type: Object,
      required: true,
    },
    // eslint-disable-next-line vue/no-unused-properties -- Used inside mergeRequestQueryVariables
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      state: {},
    };
  },
  computed: {
    iconName() {
      return ICON_NAMES[this.check.status.toLowerCase()];
    },
    failureReason() {
      if (!this.state.mergeAfter) return null;

      return sprintf(s__('mrWidget|Cannot merge until %{mergeAfter}'), {
        mergeAfter: dateFormatter.format(new Date(this.state.mergeAfter)),
      });
    },
  },
};
</script>

<template>
  <div class="gl-py-3 gl-pl-7 gl-pr-4">
    <div class="gl-flex">
      <status-icon :icon-name="iconName" :level="2" />
      <div class="gl-w-full gl-min-w-0">
        <div class="gl-flex">{{ failureReason }}</div>
      </div>
    </div>
  </div>
</template>
