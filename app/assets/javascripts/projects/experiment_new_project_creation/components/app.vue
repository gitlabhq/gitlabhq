<script>
/* eslint-disable vue/no-v-html */
import { GlBreadcrumb, GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { experiment } from '~/experimentation/utils';
import { __, s__ } from '~/locale';
import { NEW_REPO_EXPERIMENT } from '../constants';
import blankProjectIllustration from '../illustrations/blank-project.svg';
import ciCdProjectIllustration from '../illustrations/ci-cd-project.svg';
import createFromTemplateIllustration from '../illustrations/create-from-template.svg';
import importProjectIllustration from '../illustrations/import-project.svg';
import LegacyContainer from './legacy_container.vue';
import WelcomePage from './welcome.vue';

const BLANK_PANEL = 'blank_project';
const CI_CD_PANEL = 'cicd_for_external_repo';
const LAST_ACTIVE_TAB_KEY = 'new_project_last_active_tab';

const PANELS = [
  {
    key: 'blank',
    name: BLANK_PANEL,
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
      'Create a project pre-populated with the necessary files to get you started quickly.',
    ),
    illustration: createFromTemplateIllustration,
  },
  {
    key: 'import',
    name: 'import_project',
    selector: '#import-project-pane',
    title: s__('ProjectsNew|Import project'),
    description: s__(
      'Migrate your data from an external source like GitHub, Bitbucket, or another instance of GitLab.',
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
    GlBreadcrumb,
    GlIcon,
    WelcomePage,
    LegacyContainer,
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

  data() {
    return {
      activeTab: null,
    };
  },

  computed: {
    decoratedPanels() {
      const PANEL_TITLES = experiment(NEW_REPO_EXPERIMENT, {
        use: () => ({
          blank: s__('ProjectsNew|Create blank project'),
          import: s__('ProjectsNew|Import project'),
        }),
        try: () => ({
          blank: s__('ProjectsNew|Create blank project/repository'),
          import: s__('ProjectsNew|Import project/repository'),
        }),
      });

      return PANELS.map(({ key, title, ...el }) => ({
        ...el,
        title: PANEL_TITLES[key] !== undefined ? PANEL_TITLES[key] : title,
      }));
    },

    availablePanels() {
      if (this.isCiCdAvailable) {
        return this.decoratedPanels;
      }

      return this.decoratedPanels.filter((p) => p.name !== CI_CD_PANEL);
    },

    activePanel() {
      return this.decoratedPanels.find((p) => p.name === this.activeTab);
    },

    breadcrumbs() {
      if (!this.activeTab || !this.activePanel) {
        return null;
      }

      return [
        { text: __('New project'), href: '#' },
        { text: this.activePanel.title, href: `#${this.activeTab}` },
      ];
    },
  },

  created() {
    this.handleLocationHashChange();

    if (this.hasErrors) {
      this.activeTab = localStorage.getItem(LAST_ACTIVE_TAB_KEY) || BLANK_PANEL;
    }

    window.addEventListener('hashchange', () => {
      this.handleLocationHashChange();
      this.resetProjectErrors();
    });
    this.$root.$on('clicked::link', (e) => {
      window.location = e.target.href;
    });
  },

  methods: {
    resetProjectErrors() {
      const errorsContainer = document.querySelector('.project-edit-errors');
      if (errorsContainer) {
        errorsContainer.innerHTML = '';
      }
    },

    handleLocationHashChange() {
      this.activeTab = window.location.hash.substring(1) || null;
      if (this.activeTab) {
        localStorage.setItem(LAST_ACTIVE_TAB_KEY, this.activeTab);
      }
    },
  },

  PANELS,
};
</script>

<template>
  <welcome-page v-if="activeTab === null" :panels="availablePanels" />
  <div v-else class="row">
    <div class="col-lg-3">
      <div class="gl-text-white" v-html="activePanel.illustration"></div>
      <h4>{{ activePanel.title }}</h4>
      <p>{{ activePanel.description }}</p>
      <div
        v-if="newProjectGuidelines"
        id="new-project-guideline"
        v-safe-html="newProjectGuidelines"
      ></div>
    </div>
    <div class="col-lg-9">
      <gl-breadcrumb v-if="breadcrumbs" :items="breadcrumbs">
        <template #separator>
          <gl-icon name="chevron-right" :size="8" />
        </template>
      </gl-breadcrumb>
      <template v-for="panel in $options.PANELS">
        <legacy-container
          v-if="activeTab === panel.name"
          :key="panel.name"
          class="gl-mt-3"
          :selector="panel.selector"
        />
      </template>
    </div>
  </div>
</template>
