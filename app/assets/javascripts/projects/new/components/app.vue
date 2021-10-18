<script>
import createFromTemplateIllustration from '@gitlab/svgs/dist/illustrations/project-create-from-template-sm.svg';
import blankProjectIllustration from '@gitlab/svgs/dist/illustrations/project-create-new-sm.svg';
import importProjectIllustration from '@gitlab/svgs/dist/illustrations/project-import-sm.svg';
import ciCdProjectIllustration from '@gitlab/svgs/dist/illustrations/project-run-CICD-pipelines-sm.svg';
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { s__ } from '~/locale';
import NewNamespacePage from '~/vue_shared/new_namespace/new_namespace_page.vue';
import NewProjectPushTipPopover from './new_project_push_tip_popover.vue';

const CI_CD_PANEL = 'cicd_for_external_repo';
const PANELS = [
  {
    key: 'blank',
    name: 'blank_project',
    selector: '#blank-project-pane',
    title: s__('ProjectsNew|Create blank project'),
    description: s__(
      'ProjectsNew|Create a blank project to house your files, plan your work, and collaborate on code, among other things.',
    ),
    illustration: blankProjectIllustration,
  },
  {
    key: 'template',
    name: 'create_from_template',
    selector: '#create-from-template-pane',
    title: s__('ProjectsNew|Create from template'),
    description: s__(
      'ProjectsNew|Create a project pre-populated with the necessary files to get you started quickly.',
    ),
    illustration: createFromTemplateIllustration,
  },
  {
    key: 'import',
    name: 'import_project',
    selector: '#import-project-pane',
    title: s__('ProjectsNew|Import project'),
    description: s__(
      'ProjectsNew|Migrate your data from an external source like GitHub, Bitbucket, or another instance of GitLab.',
    ),
    illustration: importProjectIllustration,
  },
  {
    key: 'ci',
    name: CI_CD_PANEL,
    selector: '#ci-cd-project-pane',
    title: s__('ProjectsNew|Run CI/CD for external repository'),
    description: s__('ProjectsNew|Connect your external repository to GitLab CI/CD.'),
    illustration: ciCdProjectIllustration,
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
  },

  computed: {
    availablePanels() {
      return this.isCiCdAvailable ? PANELS : PANELS.filter((p) => p.name !== CI_CD_PANEL);
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
    :initial-breadcrumb="s__('New project')"
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
