<script>
import { GlButton, GlIcon, GlLink } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { helpPagePath } from '~/helpers/help_page_helper';

import { i18n } from '../constants';

import { addProjectToSlack } from '../api';
import ProjectsDropdown from './projects_dropdown.vue';

export default {
  components: {
    GlButton,
    GlIcon,
    GlLink,
    ProjectsDropdown,
  },
  props: {
    projects: {
      type: Array,
      required: false,
      default: () => [],
    },
    isSignedIn: {
      type: Boolean,
      required: true,
    },
    signInPath: {
      type: String,
      required: true,
    },
    slackLinkPath: {
      type: String,
      required: true,
    },
    gitlabLogoPath: {
      type: String,
      required: true,
    },
    slackLogoPath: {
      type: String,
      required: true,
    },
  },
  i18n,
  learnMoreLink: helpPagePath('user/project/integrations/gitlab_slack_application', {
    anchor: 'install-the-gitlab-for-slack-app',
  }),
  data() {
    return {
      selectedProject: null,
    };
  },
  computed: {
    hasProjects() {
      return this.projects.length > 0;
    },
  },
  methods: {
    selectProject(project) {
      this.selectedProject = project;
    },
    addToSlack() {
      addProjectToSlack(this.slackLinkPath, this.selectedProject.id)
        .then((response) => visitUrl(response.data.add_to_slack_link))
        .catch(() =>
          createAlert({
            message: i18n.slackErrorMessage,
          }),
        );
    },
  },
};
</script>

<template>
  <div class="gl-mx-auto gl-mt-11 gl-max-w-max gl-text-center">
    <div v-once class="gl-my-5 gl-flex gl-items-center gl-justify-center">
      <img :src="gitlabLogoPath" :alt="$options.i18n.gitlabLogoAlt" class="gl-h-11 gl-w-11" />
      <gl-icon name="arrow-right" :size="32" class="gl-mx-5" variant="disabled" />
      <img
        :src="slackLogoPath"
        :alt="$options.i18n.slackLogoAlt"
        class="gitlab-slack-slack-logo gl-h-11 gl-w-11"
      />
    </div>

    <h2>{{ $options.i18n.title }}</h2>

    <div data-testid="gitlab-slack-content">
      <template v-if="isSignedIn">
        <div v-if="hasProjects" class="gl-mt-6">
          <p>
            {{ $options.i18n.dropdownLabel }}
          </p>

          <projects-dropdown
            :projects="projects"
            :selected-project="selectedProject"
            @project-selected="selectProject"
          />

          <div class="gl-mt-3 gl-flex gl-justify-end">
            <gl-button
              category="primary"
              variant="confirm"
              :disabled="!selectedProject"
              @click="addToSlack"
            >
              {{ $options.i18n.dropdownButtonText }}
            </gl-button>
          </div>
        </div>
        <div v-else>
          <p class="gl-mb-0">{{ $options.i18n.noProjects }}</p>
          <p>
            <span>{{ $options.i18n.noProjectsDescription }}</span>
            <gl-link :href="$options.learnMoreLink" target="_blank">{{
              $options.i18n.learnMore
            }}</gl-link
            >.
          </p>
        </div>
      </template>

      <template v-else>
        <p>{{ $options.i18n.signInLabel }}</p>
        <gl-button category="primary" variant="confirm" :href="signInPath">
          {{ $options.i18n.signInButtonText }}
        </gl-button>
      </template>
    </div>
  </div>
</template>
<style>
.gitlab-slack-slack-logo {
  transform: scale(200%); /* Slack logo SVG is scaled down 50% and has empty space around it */
}
</style>
