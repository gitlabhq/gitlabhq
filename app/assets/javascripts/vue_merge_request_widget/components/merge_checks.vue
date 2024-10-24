<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import {
  COMPONENTS,
  FAILURE_REASONS,
} from '~/vue_merge_request_widget/components/checks/constants';
import mergeRequestQueryVariablesMixin from '../mixins/merge_request_query_variables';
import mergeChecksQuery from '../queries/merge_checks.query.graphql';
import mergeChecksSubscription from '../queries/merge_checks.subscription.graphql';
import StateContainer from './state_container.vue';
import BoldText from './bold_text.vue';

export default {
  apollo: {
    state: {
      query: mergeChecksQuery,
      skip() {
        return !this.mr;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data?.project?.mergeRequest,
      subscribeToMore: {
        document() {
          return mergeChecksSubscription;
        },
        skip() {
          return !this.mr?.id;
        },
        variables() {
          return {
            issuableId: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.mr?.id),
          };
        },
        updateQuery(
          _,
          {
            subscriptionData: {
              data: { mergeRequestMergeStatusUpdated },
            },
          },
        ) {
          if (mergeRequestMergeStatusUpdated) {
            this.state = mergeRequestMergeStatusUpdated;
          }
        },
      },
    },
  },
  components: {
    GlSkeletonLoader,
    StateContainer,
    BoldText,
  },
  mixins: [mergeRequestQueryVariablesMixin],
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
      collapsed: true,
      state: {},
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.state.loading;
    },
    statusIcon() {
      if (this.warningChecks.length) {
        return 'warning';
      }

      if (this.checkingMergeChecks.length) {
        return 'loading';
      }

      return this.failedChecks.length ? 'failed' : 'success';
    },
    summaryText() {
      if (this.warningChecks.length) {
        return this.state?.userPermissions?.canMerge
          ? __('%{boldStart}Merge with caution%{boldEnd}: Override added')
          : __('%{boldStart}Ready to be merged with caution%{boldEnd}: Override added');
      }

      if (this.checkingMergeChecks.length) {
        return __('Checking if merge request can be merged...');
      }

      if (!this.failedChecks.length) {
        return this.state?.userPermissions?.canMerge
          ? __('%{boldStart}Ready to merge!%{boldEnd}')
          : __(
              '%{boldStart}Ready to merge by members who can write to the target branch.%{boldEnd}',
            );
      }

      return sprintf(
        n__(
          '%{boldStart}Merge blocked:%{boldEnd} %{count} check failed',
          '%{boldStart}Merge blocked:%{boldEnd} %{count} checks failed',
          this.failedChecks.length,
        ),
        { count: this.failedChecks.length },
      );
    },
    checks() {
      return this.state?.mergeabilityChecks || [];
    },
    sortedChecks() {
      const order = ['CHECKING', 'FAILED', 'WARNING', 'SUCCESS'];

      return [...this.checks]
        .filter((s) => {
          if (this.isStatusInactive(s) || !this.hasMessage(s)) return false;

          return this.collapsed ? this.isStatusFailed(s) || this.isStatusChecking(s) : true;
        })
        .sort((a, b) => order.indexOf(a.status) - order.indexOf(b.status));
    },
    checkingMergeChecks() {
      return this.checks.filter((c) => this.isStatusChecking(c));
    },
    failedChecks() {
      return this.checks.filter((c) => this.isStatusFailed(c));
    },
    warningChecks() {
      return this.checks.filter((c) => this.isStatusWarning(c));
    },
    showChecks() {
      return this.failedChecks.length > 0 || this.checkingMergeChecks.length || !this.collapsed;
    },
  },
  methods: {
    toggleCollapsed() {
      this.collapsed = !this.collapsed;
    },
    checkComponent(check) {
      return COMPONENTS[check.identifier.toLowerCase()] || COMPONENTS.default;
    },
    hasMessage(check) {
      return Boolean(FAILURE_REASONS[check.identifier.toLowerCase()]);
    },
    isStatusInactive(check) {
      return check.status === 'INACTIVE';
    },
    isStatusFailed(check) {
      return check.status === 'FAILED';
    },
    isStatusWarning(check) {
      return check.status === 'WARNING';
    },
    isStatusChecking(check) {
      return check.status === 'CHECKING';
    },
  },
};
</script>

<template>
  <div>
    <state-container
      :is-loading="isLoading"
      :status="statusIcon"
      is-collapsible
      collapse-on-desktop
      :collapsed="collapsed"
      :expand-details-tooltip="__('Expand merge checks')"
      :collapse-details-tooltip="__('Collapse merge checks')"
      @toggle="toggleCollapsed"
    >
      <template v-if="isLoading" #loading>
        <gl-skeleton-loader :width="334" :height="24">
          <rect x="0" y="0" width="24" height="24" rx="4" />
          <rect x="32" y="2" width="302" height="20" rx="4" />
        </gl-skeleton-loader>
      </template>
      <template v-if="!isLoading" #default>
        <bold-text :message="summaryText" />
      </template>
    </state-container>
    <div
      v-if="showChecks"
      class="gl-border-t gl-relative gl-border-t-section gl-bg-subtle"
      data-testid="merge-checks-full"
    >
      <div>
        <component
          :is="checkComponent(check)"
          v-for="(check, index) in sortedChecks"
          :key="index"
          class="gl-pl-9 gl-pr-4"
          :class="{
            'gl-border-b gl-border-b-section': index !== sortedChecks.length - 1,
          }"
          :check="check"
          :mr="mr"
          :service="service"
          data-testid="merge-check"
        />
      </div>
    </div>
  </div>
</template>
