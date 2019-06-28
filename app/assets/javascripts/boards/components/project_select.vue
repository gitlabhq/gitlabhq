<script>
import { __ } from '~/locale';
import $ from 'jquery';
import _ from 'underscore';
import Icon from '~/vue_shared/components/icon.vue';
import { GlLoadingIcon } from '@gitlab/ui';
import eventHub from '../eventhub';
import Api from '../../api';

export default {
  name: 'BoardProjectSelect',
  components: {
    Icon,
    GlLoadingIcon,
  },
  props: {
    groupId: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  data() {
    return {
      loading: true,
      selectedProject: {},
    };
  },
  computed: {
    selectedProjectName() {
      return this.selectedProject.name || __('Select a project');
    },
  },
  mounted() {
    $(this.$refs.projectsDropdown).glDropdown({
      filterable: true,
      filterRemote: true,
      search: {
        fields: ['name_with_namespace'],
      },
      clicked: ({ $el, e }) => {
        e.preventDefault();
        this.selectedProject = {
          id: $el.data('project-id'),
          name: $el.data('project-name'),
        };
        eventHub.$emit('setSelectedProject', this.selectedProject);
      },
      selectable: true,
      data: (term, callback) => {
        this.loading = true;
        return Api.groupProjects(
          this.groupId,
          term,
          {
            with_issues_enabled: true,
            with_shared: false,
            include_subgroups: true,
          },
          projects => {
            this.loading = false;
            callback(projects);
          },
        );
      },
      renderRow(project) {
        return `
            <li>
              <a href='#' class='dropdown-menu-link' data-project-id="${
                project.id
              }" data-project-name="${project.name}">
                ${_.escape(project.name)}
              </a>
            </li>
          `;
      },
      text: project => project.name,
    });
  },
};
</script>

<template>
  <div>
    <label class="label-bold prepend-top-10">{{ __('Project') }}</label>
    <div ref="projectsDropdown" class="dropdown dropdown-projects">
      <button
        class="dropdown-menu-toggle wide"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false"
      >
        {{ selectedProjectName }} <icon name="chevron-down" />
      </button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
        <div class="dropdown-title">{{ __('Projects') }}</div>
        <div class="dropdown-input">
          <input class="dropdown-input-field" type="search" :placeholder="__('Search projects')" />
          <icon name="search" class="dropdown-input-search" data-hidden="true" />
        </div>
        <div class="dropdown-content"></div>
        <div class="dropdown-loading"><gl-loading-icon /></div>
      </div>
    </div>
  </div>
</template>
