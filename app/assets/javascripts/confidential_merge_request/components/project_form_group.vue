<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '../../locale';
import createFlash from '../../flash';
import Api from '../../api';
import state from '../state';
import Dropdown from './dropdown.vue';

export default {
  components: {
    GlLink,
    GlSprintf,
    Dropdown,
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
      }
    },
    normalizeProjectData(data) {
      return data.map(p => ({
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
        .catch(e => {
          createFlash(__('Error fetching forked projects. Please try again.'));
          throw e;
        });
    },
    showWarning() {
      if (this.warningText) {
        this.warningText.classList.remove('hidden');
      }

      if (this.createBtn) {
        this.createBtn.classList.add('btn-warning');
        this.createBtn.classList.remove('btn-success');
      }
    },
  },
};
</script>

<template>
  <div class="confidential-merge-request-fork-group form-group">
    <label>{{ __('Project') }}</label>
    <div>
      <dropdown
        v-if="projects.length"
        :projects="projects"
        :selected-project="selectedProject"
        @click="selectProject"
      />
      <p class="text-muted mt-1 mb-0">
        <template v-if="projects.length">
          {{
            __(
              "To protect this issue's confidentiality, a private fork of this project was selected.",
            )
          }}
        </template>
        <template v-else>
          {{ __('No forks are available to you.') }}<br />
          <gl-sprintf
            :message="
              __(
                `To protect this issue's confidentiality, %{forkLink} and set the fork's visibility to private.`,
              )
            "
          >
            <template #forkLink>
              <a :href="newForkPath" target="_blank" class="help-link">{{
                __('fork this project')
              }}</a>
            </template>
          </gl-sprintf>
        </template>
        <gl-link
          :href="helpPagePath"
          class="w-auto p-0 d-inline-block text-primary bg-transparent"
          target="_blank"
        >
          <span class="sr-only">{{ __('Read more') }}</span>
          <i class="fa fa-question-circle" aria-hidden="true"></i>
        </gl-link>
      </p>
    </div>
  </div>
</template>
