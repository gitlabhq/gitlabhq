<script>
import { GlButton, GlButtonGroup, GlFormGroup, GlIcon, GlAlert } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';
import SingleChoiceSelector from '~/vue_shared/components/single_choice_selector.vue';
import SingleChoiceSelectorItem from '~/vue_shared/components/single_choice_selector_item.vue';

import NewProjectDestinationSelect from './project_destination_select.vue';
import Breadcrumb from './form_breadcrumb.vue';
import CommandLine from './command_line.vue';

const OPTIONS = {
  blank: {
    key: 'blank',
    value: 'blank_project',
    selector: '#blank-project-pane',
    title: s__('ProjectsNew|Create blank project'),
    description: s__(
      'ProjectsNew|Create a blank project to store your files, plan your work, and collaborate on code, among other things.',
    ),
  },
  template: {
    key: 'template',
    value: 'create_from_template',
    selector: '#create-from-template-pane',
    title: s__('ProjectsNew|Create from template'),
    description: s__(
      'ProjectsNew|Create a project pre-populated with the necessary files to get you started quickly.',
    ),
  },
  ci: {
    key: 'ci',
    value: 'cicd_for_external_repo',
    selector: '#ci-cd-project-pane',
    title: s__('ProjectsNew|Run CI/CD for external repository'),
    description: s__('ProjectsNew|Connect your external repository to GitLab CI/CD.'),
  },
  import: {
    key: 'import',
    value: 'import_project',
    selector: '#import-project-pane',
    title: s__('ProjectsNew|Import project'),
    description: s__(
      'ProjectsNew|Migrate your data from an external source like GitHub, Bitbucket, or another instance of GitLab.',
    ),
    disabledMessage: s__(
      'ProjectsNew|Contact an administrator to enable options for importing your project',
    ),
  },
  transfer: {
    key: 'transfer',
    value: 'transfer_project',
    selector: '#transfer-project-pane',
    title: s__('ProjectsNew|Direct transfer projects with a top-level Group'),
    description: s__('ProjectsNew|Migrate your data from another GitLab instance.'),
    disabledMessage: s__('ProjectsNew|Available only for projects within groups'),
  },
};

export default {
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
  },
  methods: {
    choosePersonalNamespace() {
      this.selectedNamespace = this.userNamespaceId;
    },
    chooseGroupNamespace() {
      this.selectedNamespace = null;
    },
  },
  OPTIONS,
};
</script>

<template>
  <div>
    <breadcrumb />

    <multi-step-form-template :title="__('Create new project')" :current-step="1">
      <template #form>
        <gl-form-group
          v-if="canSelectNamespace"
          :label="s__('ProjectNew|What do you want to create?')"
        >
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
          <single-choice-selector-item v-bind="$options.OPTIONS.blank" />
          <single-choice-selector-item v-bind="$options.OPTIONS.template" />
          <single-choice-selector-item
            v-if="canImportProjects && importSourcesEnabled"
            v-bind="$options.OPTIONS.ci"
          />
          <single-choice-selector-item v-if="isCiCdAvailable" v-bind="$options.OPTIONS.import">
            {{ $options.OPTIONS.import.title }}
            <div class="gl-flex gl-gap-2">
              <gl-icon name="tanuki" />
              <gl-icon name="github" />
              <gl-icon name="bitbucket" />
              <gl-icon name="gitea" />
            </div>
          </single-choice-selector-item>
          <single-choice-selector-item v-bind="$options.OPTIONS.transfer" :disabled="true" />
        </single-choice-selector>
        <gl-alert v-else variant="danger" :dismissible="false">
          {{ errorMessage }}
        </gl-alert>
      </template>
      <template #footer>
        <div v-if="newProjectGuidelines" v-safe-html="newProjectGuidelines" class="gl-mb-6"></div>
        <command-line v-if="isPersonalProject" />
      </template>
    </multi-step-form-template>
  </div>
</template>
