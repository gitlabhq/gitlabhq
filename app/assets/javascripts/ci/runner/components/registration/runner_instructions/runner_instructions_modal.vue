<script>
import {
  GlAlert,
  GlButton,
  GlModal,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlSprintf,
  GlSkeletonLoader,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/src/utils'; // eslint-disable-line no-restricted-syntax -- This content is shown in a modal, we can refer to viewport breakpoints
import { __, s__ } from '~/locale';
import getRunnerPlatformsQuery from './graphql/get_runner_platforms.query.graphql';
import {
  PLATFORM_DOCKER,
  PLATFORM_KUBERNETES,
  PLATFORM_AWS,
  LEGACY_REGISTER_HELP_URL,
} from './constants';

import RunnerCliInstructions from './instructions/runner_cli_instructions.vue';
import RunnerDockerInstructions from './instructions/runner_docker_instructions.vue';
import RunnerKubernetesInstructions from './instructions/runner_kubernetes_instructions.vue';
import RunnerAwsInstructions from './instructions/runner_aws_instructions.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlModal,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    GlSkeletonLoader,
    RunnerDockerInstructions,
  },
  directives: {
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    modalId: {
      type: String,
      required: false,
      default: 'runner-instructions-modal',
    },
    registrationToken: {
      type: String,
      required: false,
      default: null,
    },
    defaultPlatformName: {
      type: String,
      required: false,
      default: null,
    },
  },
  apollo: {
    platforms: {
      query: getRunnerPlatformsQuery,
      skip() {
        // Only load instructions once the modal is shown
        return !this.shown;
      },
      update(data) {
        return (
          data?.runnerPlatforms?.nodes.map(({ name, humanReadableName, architectures }) => {
            return {
              name,
              humanReadableName,
              architectures: architectures?.nodes || [],
            };
          }) ?? []
        );
      },
      result() {
        // If found, select the defaultSelectedPlatform.
        // Otherwise, select the first available platform
        const platform =
          this.platforms?.find(({ name }) => this.defaultPlatformName === name) ||
          this.platforms?.[0];

        this.selectPlatform(platform);
      },
      error() {
        this.toggleAlert(true);
      },
    },
  },
  data() {
    return {
      shown: false,
      platforms: [],
      selectedPlatform: null,
      showErrorAlert: false,
      platformsButtonGroupVertical: false,
    };
  },
  computed: {
    instructionsComponent() {
      if (this.selectedPlatform?.architectures?.length) {
        return RunnerCliInstructions;
      }
      switch (this.selectedPlatform?.name) {
        case PLATFORM_DOCKER:
          return RunnerDockerInstructions;
        case PLATFORM_KUBERNETES:
          return RunnerKubernetesInstructions;
        case PLATFORM_AWS:
          return RunnerAwsInstructions;
        default:
          return null;
      }
    },
  },
  methods: {
    // show() can be invoked by parent components to show the modal
    // eslint-disable-next-line vue/no-unused-properties
    show() {
      this.$refs.modal.show();
    },
    // close() can be invoked by parent components to close the modal
    close() {
      this.$refs.modal.close();
    },
    onClose() {
      this.close();
    },
    onShown() {
      this.shown = true;
    },
    selectPlatform(platform) {
      this.selectedPlatform = platform;
    },
    isPlatformSelected(platform) {
      return this.selectedPlatform.name === platform.name;
    },
    toggleAlert(state) {
      this.showErrorAlert = state;
    },
    onPlatformsButtonResize() {
      // Note, this component is a modal, so it should not be migrated to PanelBreakpointInstance
      this.platformsButtonGroupVertical = GlBreakpointInstance.getBreakpointSize() === 'xs';
    },
  },
  i18n: {
    environment: __('Environment'),
    installARunner: s__('Runners|Install a runner'),
    downloadInstallBinary: s__('Runners|Download and install binary'),
    downloadLatestBinary: s__('Runners|Download latest binary'),
    fetchError: s__('Runners|An error has occurred fetching instructions'),
    deprecationAlertTitle: s__('Runners|Support for registration tokens is deprecated'),
    deprecationAlertContent: s__(
      "Runners|In GitLab Runner 15.6, the use of registration tokens and runner parameters in the 'register' command was deprecated. They have been replaced by authentication tokens. %{linkStart}How does this impact my current registration workflow?%{linkEnd}",
    ),
  },
  LEGACY_REGISTER_HELP_URL,
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :no-focus-on-show="true"
    :title="$options.i18n.installARunner"
    v-bind="$attrs"
    hide-footer
    v-on="$listeners"
    @shown="onShown"
  >
    <gl-alert :title="$options.i18n.deprecationAlertTitle" variant="warning" :dismissible="false">
      <gl-sprintf :message="$options.i18n.deprecationAlertContent">
        <template #link="{ content }">
          <gl-link target="_blank" :href="$options.LEGACY_REGISTER_HELP_URL"
            >{{ content }} <gl-icon name="external-link"
          /></gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-alert v-if="showErrorAlert" variant="danger" @dismiss="toggleAlert(false)">
      {{ $options.i18n.fetchError }}
    </gl-alert>

    <gl-skeleton-loader v-if="!platforms.length && $apollo.loading" />

    <template v-if="platforms.length">
      <h5>
        {{ $options.i18n.environment }}
      </h5>
      <div v-gl-resize-observer="onPlatformsButtonResize">
        <gl-button-group
          :vertical="platformsButtonGroupVertical"
          :class="{ 'gl-w-full': platformsButtonGroupVertical }"
          class="gl-mb-3"
          data-testid="platform-buttons"
        >
          <gl-button
            v-for="platform in platforms"
            :key="platform.name"
            :ref="platform.name"
            :selected="isPlatformSelected(platform)"
            @click="selectPlatform(platform)"
          >
            {{ platform.humanReadableName }}
          </gl-button>
        </gl-button-group>
      </div>
    </template>

    <keep-alive>
      <component
        :is="instructionsComponent"
        :registration-token="registrationToken"
        :platform="selectedPlatform"
        @close="onClose"
        @error="toggleAlert(true)"
      />
    </keep-alive>
  </gl-modal>
</template>
