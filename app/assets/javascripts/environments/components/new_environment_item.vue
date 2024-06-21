<script>
import {
  GlBadge,
  GlButton,
  GlCollapse,
  GlDisclosureDropdown,
  GlLink,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
    GlCollapse,
    GlBadge,
    GlButton,
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
    EnvironmentApproval: () =>
      import('ee_component/environments/components/environment_approval.vue'),
  },
  directives: {
    GlTooltip,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['helpPagePath', 'projectPath'],
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
    isLastDeployment: {
      query: isLastDeployment,
      variables() {
        return { environment: this.environment };
      },
    },
  },
  i18n: {
    collapse: __('Collapse'),
    expand: __('Expand'),
    emptyState: s__(
      'Environments|There are no deployments for this environment yet. %{linkStart}Learn more about setting up deployments.%{linkEnd}',
    ),
    autoStopIn: s__('Environment|Auto stop %{time}'),
    tierTooltip: s__('Environment|Deployment tier'),
  },
  data() {
    return { visible: false };
  },
  computed: {
    icon() {
      return this.visible ? 'chevron-lg-down' : 'chevron-lg-right';
    },
    externalUrl() {
      return this.environment.externalUrl;
    },
    name() {
      return this.inFolder ? this.environment.nameWithoutType : this.environment.name;
    },
    label() {
      return this.visible ? this.$options.i18n.collapse : this.$options.i18n.expand;
    },
    lastDeployment() {
      return this.environment?.lastDeployment;
    },
    upcomingDeployment() {
      return this.environment?.upcomingDeployment;
    },
    hasDeployment() {
      return Boolean(this.environment?.upcomingDeployment || this.environment?.lastDeployment);
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
    upcomingDeploymentIid() {
      return this.environment.upcomingDeployment?.iid.toString() || '';
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
  methods: {
    toggleEnvironmentCollapse() {
      this.visible = !this.visible;
    },
  },
  deploymentClasses: [
    'gl-border-gray-100',
    'gl-border-t-solid',
    'gl-border-1',
    'gl-py-5',
    'gl-md-pl-7',
    'gl-bg-gray-10',
  ],
  deployBoardClasses: [
    'gl-border-gray-100',
    'gl-border-t-solid',
    'gl-border-1',
    'gl-py-4',
    'gl-md-pl-7',
    'gl-bg-gray-10',
  ],
};
</script>
<template>
  <div>
    <div
      class="gl-px-3 gl-pt-3 gl-pb-5 gl-display-flex gl-justify-content-space-between gl-align-items-center"
    >
      <div
        :class="{ 'gl-ml-7': inFolder }"
        class="gl-min-w-0 gl-mr-4 gl-display-flex gl-align-items-center"
      >
        <gl-button
          class="gl-mr-4 gl-min-w-fit"
          :icon="icon"
          :aria-label="label"
          size="small"
          category="secondary"
          @click="toggleEnvironmentCollapse"
        />
        <gl-link
          v-gl-tooltip
          :href="environment.environmentPath"
          class="gl-text-blue-500 gl-text-truncate"
          :class="{ 'gl-font-bold': visible }"
          :title="name"
        >
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
      <div class="gl-display-flex gl-align-items-center">
        <p v-if="canShowAutoStopDate" class="gl-font-sm gl-text-gray-700 gl-mr-5 gl-mb-0">
          <gl-sprintf :message="$options.i18n.autoStopIn">
            <template #time>
              <time-ago-tooltip :time="environment.autoStopAt" css-class="gl-font-bold" />
            </template>
          </gl-sprintf>
        </p>
        <div class="btn-group table-action-buttons" role="group">
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
      </div>
    </div>
    <gl-collapse :visible="visible">
      <template v-if="hasDeployment">
        <div v-if="lastDeployment" :class="$options.deploymentClasses">
          <deployment
            :deployment="lastDeployment"
            :visible="visible"
            :class="{ 'gl-ml-7': inFolder }"
            latest
            class="gl-pl-4"
          />
        </div>
        <div
          v-if="upcomingDeployment"
          :class="$options.deploymentClasses"
          data-testid="upcoming-deployment-content"
        >
          <deployment
            :deployment="upcomingDeployment"
            :visible="visible"
            :class="{ 'gl-ml-7': inFolder }"
            class="gl-pl-4"
          >
            <template #approval>
              <environment-approval
                :required-approval-count="environment.requiredApprovalCount"
                :deployment-web-path="upcomingDeployment.webPath"
              />
            </template>
          </deployment>
        </div>
      </template>
      <div v-else :class="$options.deploymentClasses">
        <gl-sprintf :message="$options.i18n.emptyState">
          <template #link="{ content }">
            <gl-link :href="helpPagePath">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </div>
      <div v-if="rolloutStatus" :class="$options.deployBoardClasses">
        <deploy-board-wrapper
          :rollout-status="rolloutStatus"
          :environment="environment"
          :class="{ 'gl-ml-7': inFolder }"
          class="gl-pl-4"
        />
      </div>
      <div v-if="hasOpenedAlert" class="gl-bg-gray-10 gl-md-px-7">
        <environment-alert :environment="environment" class="gl-pl-4 gl-py-5" />
      </div>
    </gl-collapse>
  </div>
</template>
