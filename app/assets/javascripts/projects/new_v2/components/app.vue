<script>
import { GlButton, GlButtonGroup, GlFormGroup, GlIcon, GlAlert } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
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
    rootPath: {
      default: '/',
    },
    projectsUrl: {
      default: null,
    },
    userNamespaceId: {
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
      default: null,
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
      selectedNamespace:
        this.namespaceId && this.canSelectNamespace ? this.namespaceId : this.userNamespaceId,
      selectedProjectType: OPTIONS.blank.value,
      currentStep: 1,
      rootUrl: this.rootPath,
    };
  },

  computed: {
    isPersonalProject() {
      return this.selectedNamespace === this.userNamespaceId;
    },
    canChooseOption() {
      if (!this.isPersonalProject) return true;
      return this.canCreateProject && this.userProjectLimit > 0;
    },
    errorMessage() {
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
          limit: this.userProjectLimit,
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
  },

  created() {
    this.setStepFromLocationHash();
  },

  methods: {
    choosePersonalNamespace() {
      this.selectedNamespace = this.userNamespaceId;
    },
    chooseGroupNamespace() {
      this.selectedNamespace = null;
    },
    selectProjectType(value) {
      this.selectedProjectType = value;
    },
    onBack() {
      this.currentStep -= 1;
      setLocationHash();
    },
    onNext() {
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
        <gl-form-group :label="s__('ProjectNew|What do you want to create?')">
          <gl-button-group class="gl-w-full">
            <gl-button
              category="primary"
              variant="default"
              size="medium"
              :selected="isPersonalProject"
              class="gl-w-full"
              data-testid="personal-namespace-button"
              @click="choosePersonalNamespace"
            >
              {{ s__('ProjectsNew|A personal project') }}
            </gl-button>
            <gl-button
              category="primary"
              variant="default"
              size="medium"
              :selected="!isPersonalProject"
              class="gl-w-full"
              data-testid="group-namespace-button"
              @click="chooseGroupNamespace"
            >
              {{ s__('ProjectsNew|A project within a group') }}
            </gl-button>
          </gl-button-group>
        </gl-form-group>

        <gl-form-group v-if="!isPersonalProject" :label="s__('ProjectsNew|Choose a group')">
          <new-project-destination-select
            :namespace-full-path="namespaceFullPath"
            :namespace-id="namespaceId"
            :track-label="trackLabel"
            :root-url="rootUrl"
            :groups-only="true"
            data-testid="group-selector"
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
      <template #next>
        <gl-button
          category="primary"
          variant="confirm"
          data-testid="new-project-next"
          @click="onNext"
        >
          {{ __('Next step') }}
        </gl-button>
      </template>
      <template #footer>
        <div v-if="newProjectGuidelines" v-safe-html="newProjectGuidelines" class="gl-mb-6"></div>
        <command-line v-if="isPersonalProject" />
      </template>
    </multi-step-form-template>

    <component
      :is="step2Component"
      v-if="currentStep === 2"
      :key="selectedProjectOption.key"
      :option="selectedProjectOption"
      :namespace-id="selectedNamespace"
      data-testid="new-project-step2"
      @back="onBack"
      @next="onNext"
    />

    <import-by-url-form v-if="currentStep === 3" @back="onBack" />
  </div>
</template>
