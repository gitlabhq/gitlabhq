<script>
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import autoMergeFailedQuery from '../../queries/states/auto_merge_failed.query.graphql';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetAutoMergeFailed',
  components: {
    statusIcon,
    GlLoadingIcon,
    GlButton,
  },
  mixins: [glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
  apollo: {
    mergeError: {
      query: autoMergeFailedQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
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
      mergeError: this.glFeatures.mergeRequestWidgetGraphql ? null : this.mr.mergeError,
      isRefreshing: false,
    };
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
  <div class="mr-widget-body media">
    <status-icon status="warning" />
    <div class="media-body space-children gl-display-flex gl-flex-wrap gl-align-items-center">
      <span class="bold">
        <template v-if="mergeError">{{ mergeError }}</template>
        {{ s__('mrWidget|This merge request failed to be merged automatically') }}
      </span>
      <gl-button
        :disabled="isRefreshing"
        category="secondary"
        variant="default"
        size="small"
        @click="refreshWidget"
      >
        <gl-loading-icon v-if="isRefreshing" size="sm" :inline="true" />
        {{ s__('mrWidget|Refresh') }}
      </gl-button>
    </div>
  </div>
</template>
