<script>
import {
  GlAlert,
  GlButton,
  GlModal,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
  GlLoadingIcon,
  GlSkeletonLoader,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { isEmpty } from 'lodash';
import { __, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import {
  INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES,
  REGISTRATION_TOKEN_PLACEHOLDER,
} from './constants';
import getRunnerPlatformsQuery from './graphql/get_runner_platforms.query.graphql';
import getRunnerSetupInstructionsQuery from './graphql/get_runner_setup.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlModal,
    GlIcon,
    GlLoadingIcon,
    GlSkeletonLoader,
    ModalCopyButton,
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
        // If it is set and available, select the defaultSelectedPlatform.
        // Otherwise, select the first available platform
        this.selectPlatform(this.defaultPlatformName || this.platforms?.[0].name);
      },
      error() {
        this.toggleAlert(true);
      },
    },
    instructions: {
      query: getRunnerSetupInstructionsQuery,
      skip() {
        return !this.shown || !this.selectedPlatform;
      },
      variables() {
        return {
          platform: this.selectedPlatform,
          architecture: this.selectedArchitecture || '',
        };
      },
      update(data) {
        return data?.runnerSetup;
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
      selectedArchitecture: null,
      showAlert: false,
      instructions: {},
      platformsButtonGroupVertical: false,
    };
  },
  computed: {
    instructionsEmpty() {
      return isEmpty(this.instructions);
    },
    architectures() {
      return this.platforms.find(({ name }) => name === this.selectedPlatform)?.architectures || [];
    },
    binaryUrl() {
      return this.architectures.find(({ name }) => name === this.selectedArchitecture)
        ?.downloadLocation;
    },
    instructionsWithoutArchitecture() {
      return INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES[this.selectedPlatform]?.instructions;
    },
    runnerInstallationLink() {
      return INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES[this.selectedPlatform]?.link;
    },
    registerInstructionsWithToken() {
      const { registerInstructions } = this.instructions || {};

      if (this.registrationToken) {
        return registerInstructions?.replace(
          REGISTRATION_TOKEN_PLACEHOLDER,
          this.registrationToken,
        );
      }
      return registerInstructions;
    },
  },
  updated() {
    // Refocus on dom changes, after loading data
    this.refocusSelectedPlatformButton();
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    onShown() {
      this.shown = true;
      this.refocusSelectedPlatformButton();
    },
    refocusSelectedPlatformButton() {
      // On modal opening, the first focusable element is auto-focused by bootstrap-vue
      // This can be confusing for users, because the wrong platform button can
      // get focused when setting a `defaultPlatformName`.
      // This method refocuses the expected button.
      // See more about this auto-focus: https://bootstrap-vue.org/docs/components/modal#auto-focus-on-open
      this.$refs[this.selectedPlatform]?.[0].$el.focus();
    },
    selectPlatform(platformName) {
      this.selectedPlatform = platformName;

      // Update architecture when platform changes
      const arch = this.architectures.find(({ name }) => name === this.selectedArchitecture);
      if (arch) {
        this.selectArchitecture(arch.name);
      } else {
        this.selectArchitecture(this.architectures[0]?.name);
      }
    },
    selectArchitecture(architecture) {
      this.selectedArchitecture = architecture;
    },
    toggleAlert(state) {
      this.showAlert = state;
    },
    onPlatformsButtonResize() {
      if (bp.getBreakpointSize() === 'xs') {
        this.platformsButtonGroupVertical = true;
      } else {
        this.platformsButtonGroupVertical = false;
      }
    },
  },
  i18n: {
    environment: __('Environment'),
    installARunner: s__('Runners|Install a runner'),
    architecture: s__('Runners|Architecture'),
    downloadInstallBinary: s__('Runners|Download and install binary'),
    downloadLatestBinary: s__('Runners|Download latest binary'),
    registerRunnerCommand: s__('Runners|Command to register runner'),
    fetchError: s__('Runners|An error has occurred fetching instructions'),
    copyInstructions: s__('Runners|Copy instructions'),
    viewInstallationInstructions: s__('Runners|View installation instructions'),
  },
  closeButton: {
    text: __('Close'),
    attributes: [{ variant: 'default' }],
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    :title="$options.i18n.installARunner"
    :action-secondary="$options.closeButton"
    v-bind="$attrs"
    v-on="$listeners"
    @shown="onShown"
  >
    <gl-alert v-if="showAlert" variant="danger" @dismiss="toggleAlert(false)">
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
            :selected="selectedPlatform === platform.name"
            @click="selectPlatform(platform.name)"
          >
            {{ platform.humanReadableName }}
          </gl-button>
        </gl-button-group>
      </div>
    </template>
    <template v-if="architectures.length">
      <template v-if="selectedPlatform">
        <h5>
          {{ $options.i18n.architecture }}
          <gl-loading-icon v-if="$apollo.loading" size="sm" inline />
        </h5>

        <gl-dropdown class="gl-mb-3" :text="selectedArchitecture">
          <gl-dropdown-item
            v-for="architecture in architectures"
            :key="architecture.name"
            is-check-item
            :is-checked="selectedArchitecture === architecture.name"
            data-testid="architecture-dropdown-item"
            @click="selectArchitecture(architecture.name)"
          >
            {{ architecture.name }}
          </gl-dropdown-item>
        </gl-dropdown>
        <div class="gl-sm-display-flex gl-align-items-center gl-mb-3">
          <h5>{{ $options.i18n.downloadInstallBinary }}</h5>
          <gl-button
            v-if="binaryUrl"
            class="gl-ml-auto"
            :href="binaryUrl"
            download
            icon="download"
            data-testid="binary-download-button"
          >
            {{ $options.i18n.downloadLatestBinary }}
          </gl-button>
        </div>
      </template>
      <template v-if="!instructionsEmpty">
        <div class="gl-display-flex">
          <pre
            class="gl-bg-gray gl-flex-grow-1 gl-white-space-pre-line"
            data-testid="binary-instructions"
            >{{ instructions.installInstructions }}</pre
          >
          <modal-copy-button
            :title="$options.i18n.copyInstructions"
            :text="instructions.installInstructions"
            :modal-id="$options.modalId"
            css-classes="gl-align-self-start gl-ml-2 gl-mt-2"
            category="tertiary"
          />
        </div>

        <h5 class="gl-mb-3">{{ $options.i18n.registerRunnerCommand }}</h5>
        <div class="gl-display-flex">
          <pre
            class="gl-bg-gray gl-flex-grow-1 gl-white-space-pre-line"
            data-testid="register-command"
            >{{ registerInstructionsWithToken }}</pre
          >
          <modal-copy-button
            :title="$options.i18n.copyInstructions"
            :text="registerInstructionsWithToken"
            :modal-id="$options.modalId"
            css-classes="gl-align-self-start gl-ml-2 gl-mt-2"
            category="tertiary"
          />
        </div>
      </template>
    </template>
    <template v-else>
      <div>
        <p>{{ instructionsWithoutArchitecture }}</p>
        <gl-button :href="runnerInstallationLink">
          <gl-icon name="external-link" />
          {{ $options.i18n.viewInstallationInstructions }}
        </gl-button>
      </div>
    </template>
  </gl-modal>
</template>
