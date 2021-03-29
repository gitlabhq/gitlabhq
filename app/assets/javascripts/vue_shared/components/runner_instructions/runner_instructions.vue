<script>
import {
  GlAlert,
  GlButton,
  GlModal,
  GlModalDirective,
  GlButtonGroup,
  GlDropdown,
  GlDropdownItem,
  GlIcon,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { __, s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import {
  PLATFORMS_WITHOUT_ARCHITECTURES,
  INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES,
} from './constants';
import getRunnerPlatforms from './graphql/queries/get_runner_platforms.query.graphql';
import getRunnerSetupInstructions from './graphql/queries/get_runner_setup.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlButtonGroup,
    GlDropdown,
    GlDropdownItem,
    GlModal,
    GlIcon,
    ModalCopyButton,
  },
  directives: {
    GlModalDirective,
  },
  inject: {
    projectPath: {
      default: '',
    },
    groupPath: {
      default: '',
    },
  },
  apollo: {
    runnerPlatforms: {
      query: getRunnerPlatforms,
      variables() {
        return {
          projectPath: this.projectPath,
          groupPath: this.groupPath,
        };
      },
      error() {
        this.showAlert = true;
      },
      result({ data }) {
        this.project = data?.project;
        this.group = data?.group;

        this.selectPlatform(this.platforms[0].name);
      },
    },
  },
  data() {
    return {
      showAlert: false,
      selectedPlatformArchitectures: [],
      selectedPlatform: {
        name: '',
      },
      selectedArchitecture: {},
      runnerPlatforms: {},
      instructions: {},
      project: {},
      group: {},
    };
  },
  computed: {
    isPlatformSelected() {
      return Object.keys(this.selectedPlatform).length > 0;
    },
    instructionsEmpty() {
      return isEmpty(this.instructions);
    },
    groupId() {
      return this.group?.id ?? '';
    },
    projectId() {
      return this.project?.id ?? '';
    },
    platforms() {
      return this.runnerPlatforms?.nodes;
    },
    hasArchitecureList() {
      return !PLATFORMS_WITHOUT_ARCHITECTURES.includes(this.selectedPlatform?.name);
    },
    instructionsWithoutArchitecture() {
      return INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES[this.selectedPlatform.name]?.instructions;
    },
    runnerInstallationLink() {
      return INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES[this.selectedPlatform.name]?.link;
    },
  },
  methods: {
    selectPlatform(name) {
      this.selectedPlatform = this.platforms.find((platform) => platform.name === name);
      if (this.hasArchitecureList) {
        this.selectedPlatformArchitectures = this.selectedPlatform?.architectures?.nodes;
        [this.selectedArchitecture] = this.selectedPlatformArchitectures;
        this.selectArchitecture(this.selectedArchitecture);
      }
    },
    selectArchitecture(architecture) {
      this.selectedArchitecture = architecture;

      this.$apollo.addSmartQuery('instructions', {
        variables() {
          return {
            platform: this.selectedPlatform.name,
            architecture: this.selectedArchitecture.name,
            projectId: this.projectId,
            groupId: this.groupId,
          };
        },
        query: getRunnerSetupInstructions,
        update(data) {
          return data?.runnerSetup;
        },
        error() {
          this.showAlert = true;
        },
      });
    },
    toggleAlert(state) {
      this.showAlert = state;
    },
  },
  modalId: 'installation-instructions-modal',
  i18n: {
    installARunner: s__('Runners|Install a Runner'),
    architecture: s__('Runners|Architecture'),
    downloadInstallBinary: s__('Runners|Download and Install Binary'),
    downloadLatestBinary: s__('Runners|Download Latest Binary'),
    registerRunner: s__('Runners|Register Runner'),
    method: __('Method'),
    fetchError: s__('Runners|An error has occurred fetching instructions'),
    instructions: s__('Runners|Show Runner installation instructions'),
    copyInstructions: s__('Runners|Copy instructions'),
  },
  closeButton: {
    text: __('Close'),
    attributes: [{ variant: 'default' }],
  },
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal-directive="$options.modalId"
      class="gl-mt-4"
      data-testid="show-modal-button"
    >
      {{ $options.i18n.instructions }}
    </gl-button>
    <gl-modal
      :modal-id="$options.modalId"
      :title="$options.i18n.installARunner"
      :action-secondary="$options.closeButton"
    >
      <gl-alert v-if="showAlert" variant="danger" @dismiss="toggleAlert(false)">
        {{ $options.i18n.fetchError }}
      </gl-alert>
      <h5>{{ __('Environment') }}</h5>
      <gl-button-group class="gl-mb-5">
        <gl-button
          v-for="platform in platforms"
          :key="platform.name"
          data-testid="platform-button"
          @click="selectPlatform(platform.name)"
        >
          {{ platform.humanReadableName }}
        </gl-button>
      </gl-button-group>
      <template v-if="hasArchitecureList">
        <template v-if="isPlatformSelected">
          <h5>
            {{ $options.i18n.architecture }}
          </h5>
          <gl-dropdown class="gl-mb-5" :text="selectedArchitecture.name">
            <gl-dropdown-item
              v-for="architecture in selectedPlatformArchitectures"
              :key="architecture.name"
              data-testid="architecture-dropdown-item"
              @click="selectArchitecture(architecture)"
            >
              {{ architecture.name }}
            </gl-dropdown-item>
          </gl-dropdown>
          <div class="gl-display-flex gl-align-items-center gl-mb-5">
            <h5>{{ $options.i18n.downloadInstallBinary }}</h5>
            <gl-button
              class="gl-ml-auto"
              :href="selectedArchitecture.downloadLocation"
              download
              data-testid="binary-download-button"
            >
              {{ $options.i18n.downloadLatestBinary }}
            </gl-button>
          </div>
        </template>
        <template v-if="!instructionsEmpty">
          <div class="gl-display-flex">
            <pre
              class="gl-bg-gray gl-flex-fill-1 gl-white-space-pre-line"
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

          <hr />
          <h5 class="gl-mb-5">{{ $options.i18n.registerRunner }}</h5>
          <h5 class="gl-mb-5">{{ $options.i18n.method }}</h5>
          <div class="gl-display-flex">
            <pre
              class="gl-bg-gray gl-flex-fill-1 gl-white-space-pre-line"
              data-testid="runner-instructions"
            >
            {{ instructions.registerInstructions }}
          </pre
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
  </div>
</template>
