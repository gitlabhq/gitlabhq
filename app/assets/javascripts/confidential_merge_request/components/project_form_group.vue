<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { createAlert } from '~/alert';
import Api from '~/api';
import { __ } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import state from '../state';
import Dropdown from './dropdown.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    Dropdown,
    HelpIcon,
  },
  props: {
    namespacePath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    newForkPath: {
      type: String,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      projects: [],
    };
  },
  computed: {
    selectedProject() {
      return state.selectedProject;
    },
  },
  mounted() {
    this.fetchProjects();
    this.createBtn = document.querySelector('.js-create-target');
    this.warningText = document.querySelector('.js-exposed-info-warning');
  },
  methods: {
    selectProject(project) {
      if (project) {
        Object.assign(state, {
          selectedProject: project,
        });

        if (project.namespaceFullPath !== this.namespacePath) {
          this.showWarning();
        }
      } else if (this.createBtn) {
        this.createBtn.setAttribute('disabled', 'disabled');
        this.createBtn.classList.add('disabled');
      }
    },
    normalizeProjectData(data) {
      return data.map((p) => ({
        id: p.id,
        name: p.name_with_namespace,
        pathWithNamespace: p.path_with_namespace,
        namespaceFullpath: p.namespace.full_path,
      }));
    },
    fetchProjects() {
      Api.projectForks(this.projectPath, {
        with_merge_requests_enabled: true,
        min_access_level: 30,
        visibility: 'private',
      })
        .then(({ data }) => {
          this.projects = this.normalizeProjectData(data);
          this.selectProject(this.projects[0]);
        })
        .catch((e) => {
          createAlert({
            message: __('Error fetching forked projects. Please try again.'),
          });
          throw e;
        });
    },
    showWarning() {
      if (this.warningText) {
        this.warningText.classList.remove('gl-hidden');
      }
    },
  },
  i18n: {
    project: __('Project'),
    privateForkSelected: __(
      "To protect this issue's confidentiality, a private fork of this project was selected.",
    ),
    noForks: __('No forks are available to you.'),
    forkTheProject: __(
      `To protect this issue's confidentiality, %{linkStart}fork this project%{linkEnd} and set the fork's visibility to private.`,
    ),
    readMore: __('Read more'),
  },
};
</script>

<template>
  <div class="confidential-merge-request-fork-group form-group">
    <label>{{ $options.i18n.project }}</label>
    <div>
      <dropdown
        v-if="projects.length"
        :projects="projects"
        :selected-project="selectedProject"
        @select="selectProject"
      />
      <p class="gl-mb-0 gl-mt-1 gl-text-subtle">
        <template v-if="projects.length">
          {{ $options.i18n.privateForkSelected }}
        </template>
        <template v-else>
          {{ $options.i18n.noForks }}<br />
          <gl-sprintf :message="$options.i18n.forkTheProject">
            <template #link="{ content }">
              <a :href="newForkPath" target="_blank" class="help-link">{{ content }}</a>
            </template>
          </gl-sprintf>
        </template>
        <gl-link
          :href="helpPagePath"
          class="gl-inline-block gl-w-auto gl-bg-transparent gl-p-0"
          target="_blank"
        >
          <help-icon :aria-label="$options.i18n.readMore" />
        </gl-link>
      </p>
    </div>
  </div>
</template>
