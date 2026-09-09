<script>
import { GlToggle, GlLink, GlSprintf, GlProgressBar } from '@gitlab/ui';
import DuoReadinessAgentConfigRow from 'ee_component/pages/projects/shared/permissions/components/duo_readiness_agent_config_row.vue';
import DuoReadinessPlatformRow from 'ee_component/pages/projects/shared/permissions/components/duo_readiness_platform_row.vue';
import DuoReadinessRunnerRow from 'ee_component/pages/projects/shared/permissions/components/duo_readiness_runner_row.vue';
import DuoOrbitRow from 'ee_component/pages/projects/shared/permissions/components/duo_orbit_row.vue';
import DuoMcpRow from 'ee_component/pages/projects/shared/permissions/components/duo_mcp_row.vue';
import CascadingLockIcon from '~/namespaces/cascading_settings/components/cascading_lock_icon.vue';
import { n__, s__ } from '~/locale';
import {
  duoFlowHelpPath,
  STATUS_DONE,
  STATUS_TODO,
  STATUS_BLOCKED,
  STATUS_LOADING,
} from '../constants';
import DuoReadinessRow from './duo_readiness_row.vue';
import DuoLocalSetupSection from './duo_local_setup_section.vue';

const REQUIRED_STEP_COUNT = 5;

export default {
  name: 'DuoReadinessCard',
  components: {
    GlToggle,
    GlLink,
    GlSprintf,
    GlProgressBar,
    CascadingLockIcon,
    DuoReadinessRow,
    DuoReadinessPlatformRow,
    DuoReadinessRunnerRow,
    DuoReadinessAgentConfigRow,
    DuoOrbitRow,
    DuoMcpRow,
    DuoLocalSetupSection,
  },
  props: {
    duoEnabledSetting: {
      type: Object,
      required: true,
    },
    duoReadiness: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoOrbit: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoMcp: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    projectFullPath: {
      type: String,
      required: false,
      default: '',
    },
    duoFeaturesLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    duoAvailabilityCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoRemoteFlowsCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoFoundationalFlowsCascadingSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    duoEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    duoRemoteFlowsAvailability: {
      type: Boolean,
      required: false,
      default: false,
    },
    duoFoundationalFlowsAvailability: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: [
    'update:duo-enabled',
    'update:duo-remote-flows-availability',
    'update:duo-foundational-flows-availability',
  ],
  data() {
    return {
      runnerStatus: STATUS_LOADING,
    };
  },
  computed: {
    platformEnabled() {
      return Boolean(this.duoReadiness.platformEnabled);
    },
    showAvailabilityCascadingButton() {
      return (
        this.duoFeaturesLocked &&
        this.duoAvailabilityCascadingSettings &&
        Object.keys(this.duoAvailabilityCascadingSettings).length
      );
    },
    showRemoteFlowsCascadingLock() {
      return (
        this.duoRemoteFlowsCascadingSettings?.lockedByAncestor ||
        this.duoRemoteFlowsCascadingSettings?.lockedByApplicationSetting
      );
    },
    areFoundationalFlowsLocked() {
      return (
        this.duoFoundationalFlowsCascadingSettings?.lockedByAncestor ||
        this.duoFoundationalFlowsCascadingSettings?.lockedByApplicationSetting
      );
    },
    duoRowStatus() {
      return this.duoEnabled ? STATUS_DONE : STATUS_TODO;
    },
    flowExecutionRowStatus() {
      if (!this.platformEnabled || !this.duoEnabled) return STATUS_BLOCKED;

      return this.duoRemoteFlowsAvailability ? STATUS_DONE : STATUS_TODO;
    },
    foundationalFlowsRowStatus() {
      if (!this.effectiveFlowExecutionEnabled) return STATUS_BLOCKED;

      return this.duoFoundationalFlowsAvailability ? STATUS_DONE : STATUS_TODO;
    },
    effectiveFlowExecutionEnabled() {
      return this.platformEnabled && this.duoEnabled && this.duoRemoteFlowsAvailability;
    },
    showOrbitRow() {
      return Boolean(this.duoOrbit.rootGroupPath);
    },
    showMcpRow() {
      return Boolean(this.duoMcp.serversPath);
    },
    showOptionalGroup() {
      return this.platformEnabled && (this.showOrbitRow || this.showMcpRow);
    },
    doneCount() {
      return [
        this.platformEnabled,
        this.duoRowStatus === STATUS_DONE,
        this.flowExecutionRowStatus === STATUS_DONE,
        this.runnerStatus === STATUS_DONE,
        Boolean(this.duoReadiness.agentConfigPresent),
      ].filter(Boolean).length;
    },
    stepsLeft() {
      return REQUIRED_STEP_COUNT - this.doneCount;
    },
    allStepsComplete() {
      return this.stepsLeft === 0;
    },
    progressCountText() {
      if (this.allStepsComplete) return this.$options.i18n.allStepsComplete;

      return n__('DuoAgentPlatform|%d step left', 'DuoAgentPlatform|%d steps left', this.stepsLeft);
    },
    stateLine() {
      if (!this.platformEnabled) return this.$options.i18n.stateBlocked;
      if (this.allStepsComplete) return this.$options.i18n.stateReady;
      if (this.duoRowStatus !== STATUS_DONE) return this.$options.i18n.stateNotSetUp;
      if (this.flowExecutionRowStatus !== STATUS_DONE) {
        return n__(
          'DuoAgentPlatform|Chat and Code Suggestions work today. %d more step to set up flows.',
          'DuoAgentPlatform|Chat and Code Suggestions work today. %d more steps to set up flows.',
          this.stepsLeft,
        );
      }

      return n__(
        'DuoAgentPlatform|%d step left to set up flows.',
        'DuoAgentPlatform|%d steps left to set up flows.',
        this.stepsLeft,
      );
    },
  },
  duoFlowHelpPath,
  REQUIRED_STEP_COUNT,
  i18n: {
    readinessHeading: s__('DuoAgentPlatform|Run GitLab Duo agents and flows in this project'),
    requiredHeading: s__('DuoAgentPlatform|Required'),
    requiredSubtitle: s__('DuoAgentPlatform|Required for full agent and flow support.'),
    optionalHeading: s__('DuoAgentPlatform|Optional'),
    optionalSubtitle: s__(
      'DuoAgentPlatform|Features that give your agent more context to work with.',
    ),
    allStepsComplete: s__('DuoAgentPlatform|All steps complete'),
    duoRowDescription: s__('DuoAgentPlatform|Turn on AI-native features for this project.'),
    flowExecutionTitle: s__('DuoAgentPlatform|Flow execution'),
    flowExecutionDescription: s__(
      'DuoAgentPlatform|Turn on flows so agents can review merge requests, fix pipelines, and more.',
    ),
    stateNotSetUp: s__('DuoAgentPlatform|Not set up yet. To get started, turn on GitLab Duo.'),
    stateReady: s__('DuoAgentPlatform|Ready. Flows can run in this project.'),
    stateBlocked: s__('DuoAgentPlatform|Something blocks agent execution. Check the rows below.'),
  },
};
</script>

<template>
  <div class="gl-mb-6" data-testid="duo-readiness-block">
    <div class="gl-mb-4 gl-flex gl-items-start gl-justify-between gl-gap-5">
      <div class="gl-min-w-0">
        <h3 class="gl-heading-3 gl-mb-2" data-testid="readiness-heading">
          {{ $options.i18n.readinessHeading }}
        </h3>
        <p class="gl-mb-0 gl-text-sm gl-text-subtle" data-testid="readiness-state-line">
          {{ stateLine }}
        </p>
      </div>
      <div class="gl-w-1/4 gl-shrink-0 gl-text-right">
        <span class="gl-text-sm gl-text-subtle" data-testid="readiness-progress-count">
          {{ progressCountText }}
        </span>
        <gl-progress-bar
          :value="doneCount"
          :max="$options.REQUIRED_STEP_COUNT"
          :variant="allStepsComplete ? 'success' : 'primary'"
          class="gl-mt-2"
          data-testid="readiness-progress-bar"
        />
      </div>
    </div>

    <div class="gl-mb-3 gl-flex gl-flex-wrap gl-items-baseline gl-gap-3">
      <span class="gl-font-bold">{{ $options.i18n.requiredHeading }}</span>
      <span class="gl-text-sm gl-text-subtle">{{ $options.i18n.requiredSubtitle }}</span>
    </div>

    <div class="gl-border gl-overflow-hidden gl-rounded-lg">
      <duo-readiness-platform-row :readiness="duoReadiness" />

      <duo-readiness-row
        :title="duoEnabledSetting.label"
        :status="duoRowStatus"
        data-testid="duo-row"
      >
        <template #description>
          {{ $options.i18n.duoRowDescription }}
          <gl-link
            :href="duoEnabledSetting.helpPath"
            target="_blank"
            data-testid="duo-row-help-link"
            >{{ __('Learn more') }}</gl-link
          >
        </template>
        <template #title-icon>
          <cascading-lock-icon
            v-if="showAvailabilityCascadingButton"
            data-testid="duo-cascading-lock-icon"
            :is-locked-by-group-ancestor="duoAvailabilityCascadingSettings.lockedByAncestor"
            :is-locked-by-application-settings="
              duoAvailabilityCascadingSettings.lockedByApplicationSetting
            "
            :ancestor-namespace="duoAvailabilityCascadingSettings.ancestorNamespace"
            class="gl-ml-1"
          />
        </template>
        <gl-toggle
          :value="duoEnabled"
          :disabled="duoFeaturesLocked"
          :label="duoEnabledSetting.label"
          label-position="hidden"
          name="project[project_setting_attributes][duo_features_enabled]"
          data-testid="duo_features_enabled_toggle"
          @change="$emit('update:duo-enabled', $event)"
        />
      </duo-readiness-row>

      <duo-readiness-row
        :title="$options.i18n.flowExecutionTitle"
        :status="flowExecutionRowStatus"
        data-testid="flow-execution-row"
      >
        <template #title-icon>
          <cascading-lock-icon
            v-if="showRemoteFlowsCascadingLock"
            data-testid="duo-flows-cascading-lock-icon"
            :is-locked-by-group-ancestor="duoRemoteFlowsCascadingSettings.lockedByAncestor"
            :is-locked-by-application-settings="
              duoRemoteFlowsCascadingSettings.lockedByApplicationSetting
            "
            :ancestor-namespace="duoRemoteFlowsCascadingSettings.ancestorNamespace"
            class="gl-ml-1"
          />
        </template>
        <template #description>
          {{ $options.i18n.flowExecutionDescription }}
          <gl-sprintf :message="s__('DuoAgentPlatform|%{linkStart}What are flows?%{linkEnd}')">
            <template #link="{ content }">
              <gl-link :href="$options.duoFlowHelpPath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </template>
        <gl-toggle
          :value="duoRemoteFlowsAvailability"
          :disabled="!platformEnabled || !duoEnabled || showRemoteFlowsCascadingLock"
          :label="s__('DuoAgentPlatform|Remote GitLab Duo Flows')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_remote_flows_enabled]"
          data-testid="duo-remote-flows-enabled"
          @change="$emit('update:duo-remote-flows-availability', $event)"
        />
      </duo-readiness-row>

      <duo-readiness-row
        nested
        :title="s__('DuoAgentPlatform|Allow foundational flows')"
        :description="
          s__('DuoAgentPlatform|Production-ready flows built and maintained by GitLab.')
        "
        :status="foundationalFlowsRowStatus"
        data-testid="foundational-flows-row"
      >
        <template #title-icon>
          <cascading-lock-icon
            v-if="areFoundationalFlowsLocked"
            data-testid="duo-foundational-flows-cascading-lock-icon"
            :is-locked-by-group-ancestor="duoFoundationalFlowsCascadingSettings.lockedByAncestor"
            :is-locked-by-application-settings="
              duoFoundationalFlowsCascadingSettings.lockedByApplicationSetting
            "
            :ancestor-namespace="duoFoundationalFlowsCascadingSettings.ancestorNamespace"
            class="gl-ml-1"
          />
        </template>
        <gl-toggle
          :value="duoFoundationalFlowsAvailability"
          :disabled="
            !platformEnabled ||
            !duoEnabled ||
            !duoRemoteFlowsAvailability ||
            areFoundationalFlowsLocked
          "
          :label="s__('DuoAgentPlatform|Foundational GitLab Duo Flows')"
          label-position="hidden"
          name="project[project_setting_attributes][duo_foundational_flows_enabled]"
          data-testid="duo-foundational-flows-enabled"
          @change="$emit('update:duo-foundational-flows-availability', $event)"
        />
      </duo-readiness-row>

      <duo-readiness-runner-row
        :readiness="duoReadiness"
        :flow-execution-enabled="effectiveFlowExecutionEnabled"
        :project-full-path="projectFullPath"
        @status-changed="runnerStatus = $event"
      />

      <duo-readiness-agent-config-row
        :readiness="duoReadiness"
        :flow-execution-enabled="effectiveFlowExecutionEnabled"
        :project-full-path="projectFullPath"
      />
    </div>

    <div v-if="showOptionalGroup" class="gl-mt-5" data-testid="duo-optional-group">
      <div class="gl-mb-3 gl-flex gl-flex-wrap gl-items-baseline gl-gap-3">
        <span class="gl-font-bold">{{ $options.i18n.optionalHeading }}</span>
        <span class="gl-text-sm gl-text-subtle">{{ $options.i18n.optionalSubtitle }}</span>
      </div>
      <div class="gl-border gl-overflow-hidden gl-rounded-lg">
        <duo-orbit-row v-if="showOrbitRow" :orbit="duoOrbit" :project-full-path="projectFullPath" />
        <duo-mcp-row v-if="showMcpRow" :mcp="duoMcp" :project-full-path="projectFullPath" />
      </div>
    </div>

    <duo-local-setup-section class="gl-mt-5" />
  </div>
</template>
