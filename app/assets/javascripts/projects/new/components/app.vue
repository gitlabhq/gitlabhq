<script>
import PROJECT_CREATE_FROM_TEMPLATE_SVG_URL from '@gitlab/svgs/dist/illustrations/project-create-from-template-sm.svg?url';
import PROJECT_CREATE_NEW_SVG_URL from '@gitlab/svgs/dist/illustrations/project-create-new-sm.svg?url';
import PROJECT_IMPORT_SVG_URL from '@gitlab/svgs/dist/illustrations/project-import-sm.svg?url';
import PROJECT_RUN_CICD_PIPELINES_SVG_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-devops-md.svg?url';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__ } from '~/locale';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';
import NewProjectPushTipPopover from './new_project_push_tip_popover.vue';

const CI_CD_PANEL = 'cicd_for_external_repo';
const IMPORT_PROJECT_PANEL = 'import_project';
const PANELS = [
  {
    key: 'blank',
    name: 'blank_project',
    selector: '#blank-project-pane',
    title: s__('ProjectsNew|Create blank project'),
    description: s__(
      'ProjectsNew|Create a blank project to store your files, plan your work, and collaborate on code, among other things.',
    ),
    imageSrc: PROJECT_CREATE_NEW_SVG_URL,
  },
  {
    key: 'template',
    name: 'create_from_template',
    selector: '#create-from-template-pane',
    title: s__('ProjectsNew|Create from template'),
    description: s__(
      'ProjectsNew|Create a project pre-populated with the necessary files to get you started quickly.',
    ),
    imageSrc: PROJECT_CREATE_FROM_TEMPLATE_SVG_URL,
  },
  {
    key: 'import',
    name: IMPORT_PROJECT_PANEL,
    selector: '#import-project-pane',
    title: s__('ProjectsNew|Import project'),
    description: s__(
      'ProjectsNew|Migrate your data from an external source like GitHub, Bitbucket, or another instance of GitLab.',
    ),
    imageSrc: PROJECT_IMPORT_SVG_URL,
  },
  {
    key: 'ci',
    name: CI_CD_PANEL,
    selector: '#ci-cd-project-pane',
    title: s__('ProjectsNew|Run CI/CD for external repository'),
    description: s__('ProjectsNew|Connect your external repository to GitLab CI/CD.'),
    imageSrc: PROJECT_RUN_CICD_PIPELINES_SVG_URL,
  },
];

export default {
  components: {
    NewNamespacePage,
    NewProjectPushTipPopover,
  },
  directives: {
    SafeHtml,
  },
  props: {
    rootPath: {
      type: String,
      required: true,
    },
    projectsUrl: {
      type: String,
      required: true,
    },
    parentGroupUrl: {
      type: String,
      required: false,
      default: null,
    },
    parentGroupName: {
      type: String,
      required: false,
      default: '',
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
    newProjectGuidelines: {
      type: String,
      required: false,
      default: '',
    },
    canImportProjects: {
      type: Boolean,
      required: false,
      default: true,
    },
  },

  computed: {
    initialBreadcrumbs() {
      const breadcrumbs = this.parentGroupUrl
        ? [{ text: this.parentGroupName, href: this.parentGroupUrl }]
        : [
            { text: s__('Navigation|Your work'), href: this.rootPath },
            { text: s__('ProjectsNew|Projects'), href: this.projectsUrl },
          ];
      breadcrumbs.push({ text: s__('ProjectsNew|New project'), href: '#' });
      return breadcrumbs;
    },
    availablePanels() {
      if (this.isCiCdAvailable && this.canImportProjects) {
        return PANELS;
      }

      return PANELS.filter((panel) => {
        if (!this.canImportProjects && panel.name === IMPORT_PROJECT_PANEL) {
          return false;
        }

        if (!this.isCiCdAvailable && panel.name === CI_CD_PANEL) {
          return false;
        }

        return true;
      });
    },
  },

  methods: {
    resetProjectErrors() {
      const errorsContainer = document.querySelector('.project-edit-errors');
      if (errorsContainer) {
        errorsContainer.innerHTML = '';
      }
    },
  },
};
</script>

<template>
  <new-namespace-page
    :initial-breadcrumbs="initialBreadcrumbs"
    :panels="availablePanels"
    :jump-to-last-persisted-panel="hasErrors"
    :title="s__('ProjectsNew|Create new project')"
    persistence-key="new_project_last_active_tab"
    @panel-change="resetProjectErrors"
  >
    <template #extra-description>
      <div
        v-if="newProjectGuidelines"
        id="new-project-guideline"
        v-safe-html="newProjectGuidelines"
      ></div>
    </template>
    <template #welcome-footer>
      <div class="gl-pt-5 gl-text-center">
        <p>
          {{ __('You can also create a project from the command line.') }}
          <a ref="clipTip" href="#" @click.prevent>
            {{ __('Show command') }}
          </a>
          <new-project-push-tip-popover :target="() => $refs.clipTip" />
        </p>
      </div>
    </template>
  </new-namespace-page>
</template>
