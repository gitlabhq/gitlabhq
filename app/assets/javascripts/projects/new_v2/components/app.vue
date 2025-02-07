<script>
import { GlButton, GlButtonGroup, GlFormGroup, GlIcon, GlAlert } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';
import SingleChoiceSelectorItem from '~/vue_shared/components/single_choice_selector_item.vue';

import { OPTIONS } from '../constants';
import NewProjectDestinationSelect from './project_destination_select.vue';
import Breadcrumb from './form_breadcrumb.vue';
import CommandLine from './command_line.vue';
import BlankProjectForm from './blank_project_form.vue';
import TemplateProjectForm from './template_project_form.vue';
import CiCdProjectForm from './ci_cd_project_form.vue';
import ImportProjectForm from './import_project_form.vue';

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
    BlankProjectForm,
    TemplateProjectForm,
    CiCdProjectForm,
    ImportProjectForm,
  },
  directives: {
    SafeHtml,
  },
  inject: ['userNamespaceId', 'canCreateProject'],
  props: {
    rootPath: {
      type: String,
      required: false,
      default: '/',
    },
    projectsUrl: {
      type: String,
      required: false,
      default: null,
    },
    parentGroupUrl: {
      type: String,
      required: false,
      default: null,
    },
    parentGroupName: {
      type: String,
      required: false,
      default: null,
    },
    hasErrors: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCiCdAvailable: {
      type: Boolean,
      required: false,
      default: false,
    },
    canImportProjects: {
      type: Boolean,
      required: false,
      default: false,
    },
    importSourcesEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    canSelectNamespace: {
      type: Boolean,
      required: false,
      default: false,
    },
    namespaceFullPath: {
      type: String,
      required: false,
      default: null,
    },
    namespaceId: {
      type: String,
      required: false,
      default: null,
    },
    trackLabel: {
      type: String,
      required: false,
      default: null,
    },
    userProjectLimit: {
      type: Number,
      required: true,
    },
    newProjectGuidelines: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      selectedNamespace:
        this.namespaceId && this.canSelectNamespace ? this.namespaceId : this.userNamespaceId,
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
  },

  methods: {
    choosePersonalNamespace() {
      this.selectedNamespace = this.userNamespaceId;
    },
    chooseGroupNamespace() {
      this.selectedNamespace = null;
    },
  },
};
</script>

<template>
  <div>
    <breadcrumb />

    <multi-step-form-template :title="__('Create new project')" :current-step="1">
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

        <single-choice-selector v-if="canChooseOption" checked="blank_project">
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
        <gl-button category="primary" variant="confirm" size="medium">
          {{ __('Next step') }}
        </gl-button>
      </template>
      <template #footer>
        <div v-if="newProjectGuidelines" v-safe-html="newProjectGuidelines" class="gl-mb-6"></div>
        <command-line v-if="isPersonalProject" />
      </template>
    </multi-step-form-template>

    <blank-project-form :title="$options.OPTIONS.blank.title" />
    <template-project-form :title="$options.OPTIONS.template.title" />
    <ci-cd-project-form :title="$options.OPTIONS.ci.title" />
    <import-project-form :title="$options.OPTIONS.import.title" />
  </div>
</template>
