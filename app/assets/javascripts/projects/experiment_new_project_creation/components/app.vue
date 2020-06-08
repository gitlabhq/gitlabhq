<script>
import WelcomePage from './welcome.vue';
import LegacyContainer from './legacy_container.vue';
import { GlBreadcrumb, GlIcon } from '@gitlab/ui';
import { __, s__ } from '~/locale';

import blankProjectIllustration from '../illustrations/blank-project.svg';
import createFromTemplateIllustration from '../illustrations/create-from-template.svg';
import importProjectIllustration from '../illustrations/import-project.svg';
import ciCdProjectIllustration from '../illustrations/ci-cd-project.svg';

const BLANK_PANEL = 'blank_project';
const CI_CD_PANEL = 'cicd_for_external_repo';
const PANELS = [
  {
    name: BLANK_PANEL,
    selector: '#blank-project-pane',
    title: s__('ProjectsNew|Create blank project'),
    description: s__(
      'ProjectsNew|Create a blank project to house your files, plan your work, and collaborate on code, among other things.',
    ),
    illustration: blankProjectIllustration,
  },
  {
    name: 'create_from_template',
    selector: '#create-from-template-pane',
    title: s__('ProjectsNew|Create from template'),
    description: s__(
      'Create a project pre-populated with the necessary files to get you started quickly.',
    ),
    illustration: createFromTemplateIllustration,
  },
  {
    name: 'import_project',
    selector: '#import-project-pane',
    title: s__('ProjectsNew|Import project'),
    description: s__(
      'Migrate your data from an external source like GitHub, Bitbucket, or another instance of GitLab.',
    ),
    illustration: importProjectIllustration,
  },
  {
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
  },

  data() {
    return {
      activeTab: null,
    };
  },

  computed: {
    availablePanels() {
      if (this.isCiCdAvailable) {
        return PANELS;
      }

      return PANELS.filter(p => p.name !== CI_CD_PANEL);
    },

    activePanel() {
      return PANELS.find(p => p.name === this.activeTab);
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
      this.activeTab = BLANK_PANEL;
    }

    window.addEventListener('hashchange', () => {
      this.handleLocationHashChange();
      this.resetProjectErrors();
    });
    this.$root.$on('clicked::link', e => {
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
    },
  },

  PANELS,
};
</script>

<template>
  <welcome-page v-if="activeTab === null" :panels="availablePanels" />
  <div v-else class="row">
    <div class="col-lg-3">
      <div class="text-center" v-html="activePanel.illustration"></div>
      <h4>{{ activePanel.title }}</h4>
      <p>{{ activePanel.description }}</p>
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
