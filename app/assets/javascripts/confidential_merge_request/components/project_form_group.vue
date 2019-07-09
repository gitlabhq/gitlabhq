<script>
import { GlLink } from '@gitlab/ui';
import { __, sprintf } from '../../locale';
import createFlash from '../../flash';
import Api from '../../api';
import state from '../state';
import Dropdown from './dropdown.vue';

export default {
  components: {
    GlLink,
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
    noForkText() {
      return sprintf(
        __(
          "To protect this issue's confidentiality, %{link_start}fork the project%{link_end} and set the forks visiblity to private.",
        ),
        { link_start: `<a href="${this.newForkPath}" class="help-link">`, link_end: '</a>' },
        false,
      );
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
  <div class="form-group">
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
          {{ __('No forks available to you.') }}<br />
          <span v-html="noForkText"></span>
        </template>
      </p>
    </div>
  </div>
</template>
