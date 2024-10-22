<script>
import { GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import autoMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/auto_merge';
import autoMergeEnabledQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/auto_merge_enabled.query.graphql';
import { createAlert } from '~/alert';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { fetchPolicies } from '~/lib/graphql';
import { __ } from '~/locale';
import { AUTO_MERGE_STRATEGIES } from '../../constants';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import MrWidgetAuthor from '../mr_widget_author.vue';
import StateContainer from '../state_container.vue';

export default {
  name: 'MRWidgetAutoMergeEnabled',
  apollo: {
    state: {
      query: autoMergeEnabledQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project,
    },
  },
  components: {
    MrWidgetAuthor,
    GlSkeletonLoader,
    GlSprintf,
    StateContainer,
  },
  mixins: [autoMergeMixin, mergeRequestQueryVariablesMixin],
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      state: null,
      isCancellingAutoMerge: false,
      isRemovingSourceBranch: false,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.state.loading || !this.state;
    },
    stateRemoveSourceBranch() {
      if (!this.state.mergeRequest.shouldRemoveSourceBranch) return false;

      return (
        this.state.mergeRequest.shouldRemoveSourceBranch ||
        this.state.mergeRequest.forceRemoveSourceBranch
      );
    },
    canRemoveSourceBranch() {
      const { currentUserId } = this.mr;
      const mergeUserId = getIdFromGraphQLId(this.state.mergeRequest.mergeUser?.id);
      const canRemoveSourceBranch = this.state.mergeRequest.userPermissions.removeSourceBranch;

      return (
        !this.stateRemoveSourceBranch && canRemoveSourceBranch && mergeUserId === currentUserId
      );
    },
    actions() {
      const actions = [];

      if (this.loading) {
        return actions;
      }

      if (this.mr.canCancelAutomaticMerge) {
        actions.push({
          text: this.cancelButtonText,
          loading: this.isCancellingAutoMerge,
          class: 'js-cancel-auto-merge',
          testId: 'cancelAutomaticMergeButton',
          onClick: () => this.cancelAutomaticMerge(),
        });
      }

      return actions;
    },
  },
  methods: {
    cancelAutomaticMerge() {
      this.isCancellingAutoMerge = true;
      this.service
        .cancelAutomaticMerge()
        .then((res) => res.data)
        .then(() => {
          eventHub.$emit('MRWidgetUpdateRequested');
        })
        .catch(() => {
          this.isCancellingAutoMerge = false;
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
    removeSourceBranch() {
      const options = {
        sha: this.mr.sha,
        auto_merge_strategy: this.state.mergeRequest.autoMergeStrategy,
        should_remove_source_branch: true,
      };

      this.isRemovingSourceBranch = true;
      this.service
        .merge(options)
        .then((res) => res.data)
        .then((data) => {
          if (AUTO_MERGE_STRATEGIES.includes(data.status)) {
            eventHub.$emit('MRWidgetUpdateRequested');
          }
        })
        .then(() => {
          this.$apollo.queries.state.refetch();
        })
        .catch(() => {
          this.isRemovingSourceBranch = false;
          createAlert({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
  },
};
</script>
<template>
  <state-container status="scheduled" :is-loading="loading" :actions="actions" is-collapsible>
    <template #loading>
      <gl-skeleton-loader :width="334" :height="24">
        <rect x="0" y="0" width="24" height="24" rx="4" />
        <rect x="32" y="2" width="150" height="20" rx="4" />
        <rect x="190" y="2" width="144" height="20" rx="4" />
      </gl-skeleton-loader>
    </template>
    <template v-if="!loading">
      <h4 class="gl-mr-3 gl-grow" data-testid="statusText">
        <gl-sprintf :message="statusText" data-testid="statusText">
          <template #merge_author>
            <mr-widget-author
              v-if="state.mergeRequest.mergeUser"
              :author="state.mergeRequest.mergeUser"
            />
          </template>
        </gl-sprintf>
      </h4>
    </template>
  </state-container>
</template>
