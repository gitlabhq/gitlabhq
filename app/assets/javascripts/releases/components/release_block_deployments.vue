<script>
import { GlLink, GlButton, GlCollapse, GlIcon, GlBadge, GlTableLite } from '@gitlab/ui';
import Commit from '~/vue_shared/components/commit.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
import DeploymentTriggerer from '~/environments/environment_details/components/deployment_triggerer.vue';
import { __ } from '~/locale';
import { InternalEvents } from '~/tracking';
import {
  CLICK_EXPAND_DEPLOYMENTS_ON_RELEASE_PAGE,
  CLICK_ENVIRONMENT_LINK_ON_RELEASE_PAGE,
  CLICK_DEPLOYMENT_LINK_ON_RELEASE_PAGE,
} from '../constants';

export default {
  name: 'ReleaseBlockDeployments',
  components: {
    GlLink,
    GlButton,
    GlCollapse,
    GlIcon,
    GlBadge,
    GlTableLite,
    TimeAgoTooltip,
    Commit,
    DeploymentStatusLink,
    DeploymentTriggerer,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    deployments: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isDeploymentsExpanded: true,
    };
  },
  methods: {
    toggleDeploymentsExpansion() {
      this.isDeploymentsExpanded = !this.isDeploymentsExpanded;

      if (this.isDeploymentsExpanded) {
        this.trackEvent(CLICK_EXPAND_DEPLOYMENTS_ON_RELEASE_PAGE);
      }
    },
    trackEnvironmentLinkClick() {
      this.trackEvent(CLICK_ENVIRONMENT_LINK_ON_RELEASE_PAGE);
    },
    trackDeploymentLinkClick() {
      this.trackEvent(CLICK_DEPLOYMENT_LINK_ON_RELEASE_PAGE);
    },
  },
  tableFields: [
    {
      key: 'environment',
      label: __('Environment'),
      thClass: '!gl-border-t-0',
    },
    {
      key: 'status',
      label: __('Status'),
      thClass: '!gl-border-t-0',
    },
    {
      key: 'deploymentId',
      label: __('Deployment ID'),
      thClass: '!gl-border-t-0',
    },
    {
      key: 'commit',
      label: __('Commit'),
      thClass: '!gl-border-t-0',
    },
    {
      key: 'triggerer',
      label: __('Triggerer'),
      thClass: '!gl-border-t-0',
    },
    {
      key: 'created',
      label: __('Created'),
      tdClass: 'gl-whitespace-nowrap',
      thClass: '!gl-border-t-0',
    },
    {
      key: 'finished',
      label: __('Finished'),
      tdClass: 'gl-whitespace-nowrap',
      thClass: '!gl-border-t-0',
    },
  ],
};
</script>

<template>
  <div>
    <gl-button
      variant="link"
      class="!gl-text-default"
      button-text-classes="gl-heading-5"
      @click="toggleDeploymentsExpansion"
    >
      <gl-icon
        name="chevron-right"
        class="gl-transition-all"
        :class="{ 'gl-rotate-90': isDeploymentsExpanded }"
      />
      {{ __('Deployments') }}
      <gl-badge variant="neutral" class="gl-inline-block">{{ deployments.length }}</gl-badge>
    </gl-button>
    <gl-collapse v-model="isDeploymentsExpanded">
      <div class="gl-pl-6 gl-pt-3">
        <gl-table-lite :items="deployments" :fields="$options.tableFields" stacked="lg">
          <template #cell(environment)="{ item }">
            <gl-link
              :href="item.environment.url"
              data-testid="environment-name"
              @click="trackEnvironmentLinkClick"
            >
              {{ item.environment.name }}
            </gl-link>
          </template>
          <template #cell(status)="{ item }">
            <deployment-status-link :deployment="item" :status="item.status" />
          </template>
          <template #cell(deploymentId)="{ item }">
            <gl-link
              :href="item.deployment.url"
              data-testid="deployment-url"
              @click="trackDeploymentLinkClick"
            >
              {{ item.deployment.id }}
            </gl-link>
          </template>
          <template #cell(triggerer)="{ item }">
            <deployment-triggerer :triggerer="item.triggerer" />
          </template>
          <template #cell(commit)="{ item }">
            <commit
              :short-sha="item.commit.shortSha"
              :commit-url="item.commit.commitUrl"
              :title="item.commit.title"
              :show-ref-info="false"
            />
          </template>
          <template #cell(created)="{ item }">
            <time-ago-tooltip
              :time="item.createdAt"
              enable-truncation
              data-testid="deployment-created-at"
            />
          </template>
          <template #cell(finished)="{ item }">
            <time-ago-tooltip
              v-if="item.finishedAt"
              :time="item.finishedAt"
              enable-truncation
              data-testid="deployment-finished-at"
            />
          </template>
        </gl-table-lite>
      </div>
    </gl-collapse>
  </div>
</template>
