<script>
import { GlButton, GlButtonGroup, GlFormGroup, GlIcon, GlAlert } from '@gitlab/ui';
import { s__, sprintf, formatNumber } from '~/locale';
import { getLocationHash, setLocationHash } from '~/lib/utils/url_utility';
import SafeHtml from '~/vue_shared/directives/safe_html';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';
import SingleChoiceSelectorItem from '~/vue_shared/components/single_choice_selector_item.vue';

import { OPTIONS } from '../constants';
import NewProjectDestinationSelect from './project_destination_select.vue';
import Breadcrumb from './form_breadcrumb.vue';
import CommandLine from './command_line.vue';
import ImportByUrlForm from './import_by_url_form.vue';

export default {
  OPTIONS,
  components: {
    GlButton,
    GlButtonGroup,
    GlFormGroup,
    GlIcon,
    GlAlert,
    MultiStepFormTemplate,
    SingleChoiceSelector,
    SingleChoiceSelectorItem,
    NewProjectDestinationSelect,
    Breadcrumb,
    CommandLine,
    ImportByUrlForm,
  },
  directives: {
    SafeHtml,
  },
  inject: {
    projectsUrl: {
      default: null,
    },
    userNamespaceId: {
      default: null,
    },
    userNamespaceFullPath: {
      default: null,
    },
    isCiCdAvailable: {
      default: false,
    },
    canCreateProject: {
      default: false,
    },
    canImportProjects: {
      default: false,
    },
    importSourcesEnabled: {
      default: false,
    },
    canSelectNamespace: {
      default: false,
    },
    namespaceFullPath: {
      default: null,
    },
    namespaceId: {
      default: '',
    },
    trackLabel: {
      default: null,
    },
    userProjectLimit: {
      default: 0,
    },
    newProjectGuidelines: {
      default: null,
    },
  },
  data() {
    return {
      namespace: {
        id: this.namespaceId ? this.namespaceId : this.userNamespaceId,
        fullPath: this.namespaceFullPath ? this.namespaceFullPath : this.userNamespaceFullPath,
        isPersonal: this.namespaceId === '',
      },
      selectedProjectType: OPTIONS.blank.value,
      currentStep: 1,
      showValidation: false,
    };
  },

  computed: {
    canChooseOption() {
      if (this.namespace.isPersonal) {
        return this.canCreateProject && this.userProjectLimit > 0;
      }
      if (!this.canSelectNamespace) return false;
      return true;
    },
    errorMessage() {
      if (!this.canSelectNamespace && !this.namespace.isPersonal) {
        return s__('ProjectsNew|You have no groups. Create a new one or join an existing group.');
      }
      if (this.userProjectLimit === 0) {
        return s__(
          'ProjectsNew|You cannot create projects in your personal namespace. Contact your GitLab administrator.',
        );
      }
      return sprintf(
        s__(
          "ProjectsNew|You've reached your limit of %{limit} projects created. Contact your GitLab administrator.",
        ),
        {
          limit: formatNumber(this.userProjectLimit),
        },
      );
    },
    availableProjectTypes() {
      return [
        OPTIONS.blank,
        OPTIONS.template,
        ...(this.canImportProjects && this.importSourcesEnabled ? [OPTIONS.import] : []),
        ...(this.isCiCdAvailable ? [OPTIONS.ci] : []),
        OPTIONS.transfer,
      ];
    },
    selectedProjectOption() {
      return this.availableProjectTypes.find((type) => type.value === this.selectedProjectType);
    },
    step2Component() {
      return this.selectedProjectOption.component;
    },
    additionalBreadcrumb() {
      return this.currentStep === 2 ? this.selectedProjectOption : null;
    },
    isGroupSelectedValid() {
      if (this.showValidation) return this.namespace.id !== '';
      return true;
    },
  },

  created() {
    this.setStepFromLocationHash();
  },

  methods: {
    setNamespace(isPersonal) {
      if (isPersonal) {
        this.namespace.id = this.userNamespaceId;
        this.namespace.fullPath = this.userNamespaceFullPath;
        this.namespace.isPersonal = true;
      } else {
        this.namespace.id = this.namespaceId || '';
        this.namespace.fullPath = this.namespaceFullPath;
        this.namespace.isPersonal = false;
      }
      this.showValidation = false;
    },
    selectProjectType(value) {
      this.selectedProjectType = value;
    },
    onBack() {
      this.currentStep -= 1;
      setLocationHash();
    },
    onNext() {
      if (this.namespace.id === '') {
        this.showValidation = true;
        return;
      }

      this.currentStep += 1;
      setLocationHash(this.selectedProjectType);
    },
    setStepFromLocationHash() {
      const hash = getLocationHash();
      if (this.availableProjectTypes.some((type) => type.value === hash)) {
        this.selectedProjectType = hash;
        this.currentStep = 2;
      } else {
        this.currentStep = 1;
      }
    },
    onSelectNamespace({ id, fullPath }) {
      this.namespace.id = id;
      this.namespace.fullPath = fullPath;
      this.showValidation = false;
    },
  },
};
</script>

<template>
  <div>
    <breadcrumb :selected-project-type="additionalBreadcrumb" />

    <multi-step-form-template
      v-if="currentStep === 1"
      :title="__('Create new project')"
      :current-step="1"
      data-testid="new-project-step1"
    >
      <template #form>
        <gl-form-group :label="s__('ProjectNew|Where do you want to create the new project?')">
          <gl-button-group class="gl-w-full">
            <gl-button
              category="primary"
              variant="default"
              size="medium"
              :selected="namespace.isPersonal"
              class="gl-w-full"
              data-testid="personal-namespace-button"
              @click="setNamespace(true)"
            >
              {{ s__('ProjectsNew|In your personal namespace') }}
            </gl-button>
            <gl-button
              category="primary"
              variant="default"
              size="medium"
              :selected="!namespace.isPersonal"
              class="gl-w-full"
              data-testid="group-namespace-button"
              @click="setNamespace(false)"
            >
              {{ s__('ProjectsNew|In one of your groups') }}
            </gl-button>
          </gl-button-group>
        </gl-form-group>

        <gl-form-group
          v-if="!namespace.isPersonal && canChooseOption"
          :invalid-feedback="
            s__('ProjectsNew|Pick a group or namespace where you want to create this project.')
          "
          :state="isGroupSelectedValid"
          data-testid="group-selector-form-group"
        >
          <label id="group-selector" for="group">
            {{ s__('ProjectsNew|Choose a group') }}
          </label>
          <new-project-destination-select
            :namespace-full-path="namespace.fullPath"
            :namespace-id="namespace.id"
            :track-label="trackLabel"
            :groups-only="true"
            toggle-aria-labelled-by="group-selector"
            toggle-id="group"
            data-testid="group-selector"
            @onSelectNamespace="onSelectNamespace"
          />
        </gl-form-group>

        <single-choice-selector
          v-if="canChooseOption"
          :checked="selectedProjectType"
          @change="selectProjectType"
        >
          <single-choice-selector-item
            v-for="type in availableProjectTypes"
            v-bind="type"
            :key="type.key"
          >
            {{ type.title }}
            <div v-if="type.icons" class="gl-flex gl-gap-2">
              <gl-icon v-for="icon in type.icons" :key="icon" :name="icon" />
            </div>
          </single-choice-selector-item>
        </single-choice-selector>
        <gl-alert v-else variant="danger" :dismissible="false">
          {{ errorMessage }}
        </gl-alert>
      </template>
      <template v-if="canChooseOption" #next>
        <gl-button
          category="primary"
          variant="confirm"
          data-testid="new-project-next"
          @click="onNext"
        >
          {{ __('Next step') }}
        </gl-button>
      </template>
      <template v-if="canChooseOption" #footer>
        <div v-if="newProjectGuidelines" v-safe-html="newProjectGuidelines" class="gl-mb-6"></div>
        <command-line v-if="namespace.isPersonal" />
      </template>
    </multi-step-form-template>

    <component
      :is="step2Component"
      v-if="currentStep === 2"
      :key="selectedProjectOption.key"
      :option="selectedProjectOption"
      :namespace="namespace"
      data-testid="new-project-step2"
      @back="onBack"
      @next="onNext"
    />

    <import-by-url-form v-if="currentStep === 3" @back="onBack" />
  </div>
</template>
