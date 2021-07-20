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
  PLATFORMS_WITHOUT_ARCHITECTURES,
  INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES,
} from './constants';
import getRunnerPlatformsQuery from './graphql/queries/get_runner_platforms.query.graphql';
import getRunnerSetupInstructionsQuery from './graphql/queries/get_runner_setup.query.graphql';

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
      required: true,
    },
  },
  apollo: {
    platforms: {
      query: getRunnerPlatformsQuery,
      update(data) {
        return data?.runnerPlatforms?.nodes.map(({ name, humanReadableName, architectures }) => {
          return {
            name,
            humanReadableName,
            architectures: architectures?.nodes || [],
          };
        });
      },
      result() {
        // Select first platform by default
        if (this.platforms?.[0]) {
          this.selectPlatform(this.platforms[0]);
        }
      },
      error() {
        this.toggleAlert(true);
      },
    },
    instructions: {
      query: getRunnerSetupInstructionsQuery,
      skip() {
        return !this.selectedPlatform;
      },
      variables() {
        return {
          platform: this.selectedPlatformName,
          architecture: this.selectedArchitectureName || '',
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
      platforms: [],
      selectedPlatform: null,
      selectedArchitecture: null,
      showAlert: false,
      instructions: {},
      platformsButtonGroupVertical: false,
    };
  },
  computed: {
    platformsEmpty() {
      return isEmpty(this.platforms);
    },
    instructionsEmpty() {
      return isEmpty(this.instructions);
    },
    selectedPlatformName() {
      return this.selectedPlatform?.name;
    },
    selectedArchitectureName() {
      return this.selectedArchitecture?.name;
    },
    hasArchitecureList() {
      return !PLATFORMS_WITHOUT_ARCHITECTURES.includes(this.selectedPlatformName);
    },
    instructionsWithoutArchitecture() {
      return INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES[this.selectedPlatformName]?.instructions;
    },
    runnerInstallationLink() {
      return INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES[this.selectedPlatformName]?.link;
    },
  },
  methods: {
    selectPlatform(platform) {
      this.selectedPlatform = platform;

      if (!platform.architectures?.some(({ name }) => name === this.selectedArchitectureName)) {
        // Select first architecture when current value is not available
        this.selectArchitecture(platform.architectures[0]);
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
    installARunner: s__('Runners|Install a runner'),
    architecture: s__('Runners|Architecture'),
    downloadInstallBinary: s__('Runners|Download and install binary'),
    downloadLatestBinary: s__('Runners|Download latest binary'),
    registerRunnerCommand: s__('Runners|Command to register runner'),
    fetchError: s__('Runners|An error has occurred fetching instructions'),
    copyInstructions: s__('Runners|Copy instructions'),
  },
  closeButton: {
    text: __('Close'),
    attributes: [{ variant: 'default' }],
  },
};
</script>
<template>
  <gl-modal
    :modal-id="modalId"
    :title="$options.i18n.installARunner"
    :action-secondary="$options.closeButton"
  >
    <gl-alert v-if="showAlert" variant="danger" @dismiss="toggleAlert(false)">
      {{ $options.i18n.fetchError }}
    </gl-alert>

    <gl-skeleton-loader v-if="platformsEmpty && $apollo.loading" />

    <template v-if="!platformsEmpty">
      <h5>
        {{ __('Environment') }}
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
            :selected="selectedPlatform && selectedPlatform.name === platform.name"
            @click="selectPlatform(platform)"
          >
            {{ platform.humanReadableName }}
          </gl-button>
        </gl-button-group>
      </div>
    </template>
    <template v-if="hasArchitecureList">
      <template v-if="selectedPlatform">
        <h5>
          {{ $options.i18n.architecture }}
          <gl-loading-icon v-if="$apollo.loading" size="sm" inline />
        </h5>

        <gl-dropdown class="gl-mb-3" :text="selectedArchitectureName">
          <gl-dropdown-item
            v-for="architecture in selectedPlatform.architectures"
            :key="architecture.name"
            :is-check-item="true"
            :is-checked="selectedArchitectureName === architecture.name"
            data-testid="architecture-dropdown-item"
            @click="selectArchitecture(architecture)"
          >
            {{ architecture.name }}
          </gl-dropdown-item>
        </gl-dropdown>
        <div class="gl-sm-display-flex gl-align-items-center gl-mb-3">
          <h5>{{ $options.i18n.downloadInstallBinary }}</h5>
          <gl-button
            class="gl-ml-auto"
            :href="selectedArchitecture.downloadLocation"
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
            >{{ instructions.registerInstructions }}</pre
          >
          <modal-copy-button
            :title="$options.i18n.copyInstructions"
            :text="instructions.registerInstructions"
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
          {{ s__('Runners|View installation instructions') }}
        </gl-button>
      </div>
    </template>
  </gl-modal>
</template>
