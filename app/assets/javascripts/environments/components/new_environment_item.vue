<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlLink,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import isLastDeployment from '../graphql/queries/is_last_deployment.query.graphql';
import ExternalUrl from './environment_external_url.vue';
import Actions from './environment_actions.vue';
import StopComponent from './environment_stop.vue';
import Rollback from './environment_rollback.vue';
import Pin from './environment_pin.vue';
import Terminal from './environment_terminal_button.vue';
import Delete from './environment_delete.vue';
import Deployment from './deployment.vue';
import DeployBoardWrapper from './deploy_board_wrapper.vue';

export default {
  components: {
    GlDisclosureDropdown,
    GlBadge,
    GlLink,
    GlSprintf,
    Actions,
    Deployment,
    DeployBoardWrapper,
    ExternalUrl,
    StopComponent,
    Rollback,
    Pin,
    Terminal,
    TimeAgoTooltip,
    Delete,
    EnvironmentAlert: () => import('ee_component/environments/components/environment_alert.vue'),
  },
  directives: {
    GlTooltip,
  },
  inject: ['helpPagePath'],
  props: {
    environment: {
      required: true,
      type: Object,
    },
    inFolder: {
      required: false,
      default: false,
      type: Boolean,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    isLastDeployment: {
      query: isLastDeployment,
      variables() {
        return { environment: this.environment };
      },
    },
  },
  i18n: {
    emptyState: s__(
      'Environments|There are no deployments for this environment yet. %{linkStart}Learn more about setting up deployments.%{linkEnd}',
    ),
    autoStopIn: s__('Environment|Auto stop %{time}'),
    tierTooltip: s__('Environment|Deployment tier'),
    name: s__('Environments|Name'),
    deployments: s__('Environments|Deployments'),
    actions: s__('Environments|Actions'),
  },
  computed: {
    externalUrl() {
      return this.environment.externalUrl;
    },
    name() {
      return this.inFolder ? this.environment.nameWithoutType : this.environment.name;
    },
    deployments() {
      return [this.upcomingDeployment, this.lastDeployment].filter(Boolean);
    },
    lastDeployment() {
      return this.environment?.lastDeployment;
    },
    upcomingDeployment() {
      if (!this.environment?.upcomingDeployment) {
        return null;
      }
      return { ...this.environment?.upcomingDeployment, isUpcoming: true };
    },
    hasDeployment() {
      return Boolean(this.deployments.length);
    },
    tier() {
      return this.lastDeployment?.tierInYaml;
    },
    hasOpenedAlert() {
      return this.environment?.hasOpenedAlert;
    },
    actions() {
      if (!this.lastDeployment) {
        return [];
      }
      const { manualActions, scheduledActions } = this.lastDeployment;
      const combinedActions = [...(manualActions ?? []), ...(scheduledActions ?? [])];
      return combinedActions.map((action) => ({
        ...action,
      }));
    },
    canStop() {
      return this.environment?.canStop;
    },
    retryPath() {
      return this.lastDeployment?.deployable?.retryPath;
    },
    hasExtraActions() {
      return Boolean(
        this.retryPath ||
          this.canShowAutoStopDate ||
          this.terminalPath ||
          this.canDeleteEnvironment,
      );
    },
    canShowAutoStopDate() {
      if (!this.environment?.autoStopAt) {
        return false;
      }

      const autoStopDate = new Date(this.environment?.autoStopAt);
      const now = new Date();

      return now < autoStopDate;
    },
    autoStopPath() {
      return this.environment?.cancelAutoStopPath ?? '';
    },
    terminalPath() {
      return this.environment?.terminalPath ?? '';
    },
    canDeleteEnvironment() {
      return Boolean(this.environment?.canDelete && this.environment?.deletePath);
    },
    displayName() {
      return truncate(this.name, 80);
    },
    rolloutStatus() {
      return this.environment?.rolloutStatus;
    },
  },
};
</script>
<template>
  <div
    class="gl-border gl-mt-4 gl-flex gl-flex-col lg:gl-mt-0 lg:gl-flex-row lg:gl-border-x-0 lg:gl-border-t-0"
  >
    <div
      class="gl-border-b gl-flex gl-shrink-0 gl-items-baseline gl-p-4 lg:gl-w-1/5 lg:gl-border-b-0"
    >
      <strong class="gl-block gl-w-1/3 gl-flex-shrink-0 gl-pr-4 md:gl-w-1/4 lg:gl-hidden">{{
        $options.i18n.name
      }}</strong>
      <gl-link v-gl-tooltip :href="environment.environmentPath" class="gl-truncate" :title="name">
        {{ displayName }}
      </gl-link>
      <gl-badge
        v-if="tier"
        v-gl-tooltip
        :title="$options.i18n.tierTooltip"
        class="gl-ml-3 gl-font-monospace"
        >{{ tier }}</gl-badge
      >
    </div>
    <div
      class="issuable-discussion gl-border-b gl-flex gl-shrink-0 gl-flex-wrap gl-py-4 lg:gl-w-3/5 lg:gl-flex-col lg:gl-border-b-0"
    >
      <template v-if="hasDeployment">
        <strong class="gl-block gl-w-1/3 gl-flex-shrink-0 gl-px-4 md:gl-w-1/4 lg:gl-hidden">{{
          $options.i18n.deployments
        }}</strong>
        <ul class="main-notes-list timeline gl-relative -gl-ml-4 gl-w-2/3 lg:gl-w-full">
          <deployment
            v-for="deployment of deployments"
            :key="deployment.id"
            :data-testid="
              deployment.isUpcoming ? 'upcoming-deployment-content' : 'latest-deployment-content'
            "
            :deployment="deployment"
            :latest="deployment.isLast"
            class="[&:nth-child(2)]:gl-mt-4"
          />
        </ul>
      </template>
      <div v-else class="gl-px-4 gl-align-middle" data-testid="deployments-empty-state">
        <gl-sprintf :message="$options.i18n.emptyState">
          <template #link="{ content }">
            <gl-link :href="helpPagePath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
      <div v-if="rolloutStatus" class="gl-w-full">
        <deploy-board-wrapper
          :rollout-status="rolloutStatus"
          :environment="environment"
          class="gl-mt-4 gl-pl-2"
        />
      </div>
      <div v-if="hasOpenedAlert" class="gl-w-full">
        <environment-alert :environment="environment" class="gl-mt-4 gl-pl-3 gl-pt-3" />
      </div>
    </div>
    <div class="gl-flex gl-flex-grow gl-items-baseline gl-p-4">
      <strong class="gl-block gl-w-1/3 gl-flex-shrink-0 gl-pr-4 md:gl-w-1/4 lg:gl-hidden">{{
        $options.i18n.actions
      }}</strong>
      <div class="gl-ml-auto">
        <div class="btn-group" role="group">
          <external-url
            v-if="externalUrl"
            :external-url="externalUrl"
            data-track-action="click_button"
            data-track-label="environment_url"
          />

          <actions
            v-if="actions.length > 0"
            :actions="actions"
            data-track-action="click_dropdown"
            data-track-label="environment_actions"
            graphql
          />

          <stop-component
            v-if="canStop"
            :environment="environment"
            data-track-action="click_button"
            data-track-label="environment_stop"
            graphql
          />

          <gl-disclosure-dropdown
            v-if="hasExtraActions"
            text-sr-only
            no-caret
            icon="ellipsis_v"
            category="secondary"
            placement="bottom-end"
            size="small"
            :toggle-text="__('More actions')"
          >
            <rollback
              v-if="retryPath"
              :environment="environment"
              :is-last-deployment="isLastDeployment"
              :retry-url="retryPath"
              graphql
              data-track-action="click_button"
              data-track-label="environment_rollback"
            />

            <pin
              v-if="canShowAutoStopDate"
              :auto-stop-url="autoStopPath"
              graphql
              data-track-action="click_button"
              data-track-label="environment_pin"
            />

            <terminal
              v-if="terminalPath"
              :terminal-path="terminalPath"
              data-track-action="click_button"
              data-track-label="environment_terminal"
            />

            <delete
              v-if="canDeleteEnvironment"
              :environment="environment"
              data-track-action="click_button"
              data-track-label="environment_delete"
              graphql
            />
          </gl-disclosure-dropdown>
        </div>
        <p
          v-if="canShowAutoStopDate"
          class="gl-mb-0 gl-mt-3 gl-text-sm gl-text-subtle"
          data-testid="auto-stop-time"
        >
          <gl-sprintf :message="$options.i18n.autoStopIn">
            <template #time>
              <time-ago-tooltip :time="environment.autoStopAt" css-class="gl-font-bold" />
            </template>
          </gl-sprintf>
        </p>
      </div>
    </div>
  </div>
</template>
