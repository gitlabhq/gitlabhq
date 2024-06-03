<script>
import { s__ } from '~/locale';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import autoMergeFailedQuery from '../../queries/states/auto_merge_failed.query.graphql';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetAutoMergeFailed',
  components: {
    StateContainer,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    mergeError: {
      query: autoMergeFailedQuery,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest?.mergeError,
    },
  },
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      mergeError: null,
      isRefreshing: false,
    };
  },
  computed: {
    actions() {
      return [
        {
          text: s__('mrWidget|Refresh'),
          loading: this.isRefreshing,
          onClick: () => this.refreshWidget(),
        },
      ];
    },
  },
  methods: {
    refreshWidget() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested', () => {
        this.isRefreshing = false;
      });
    },
  },
};
</script>
<template>
  <state-container status="failed" :actions="actions" is-collapsible>
    <span class="gl-font-bold">
      <template v-if="mergeError">{{ mergeError }}</template>
      {{ s__('mrWidget|This merge request failed to be merged automatically') }}
    </span>
  </state-container>
</template>
