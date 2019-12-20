<script>
import $ from 'jquery';
import _ from 'underscore';
import { GlLoadingIcon } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';
import eventHub from '../eventhub';
import Api from '../../api';
import { featureAccessLevel } from '~/pages/projects/shared/permissions/constants';

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
    list: {
      type: Object,
      required: true,
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
        const additionalAttrs = {};

        if (this.list.type && this.list.type !== 'backlog') {
          additionalAttrs.min_access_level = featureAccessLevel.EVERYONE;
        }

        return Api.groupProjects(
          this.groupId,
          term,
          {
            with_issues_enabled: true,
            with_shared: false,
            include_subgroups: true,
            ...additionalAttrs,
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
              }" data-project-name="${project.name}" data-project-name-with-namespace="${
          project.name_with_namespace
        }">
                ${_.escape(project.name_with_namespace)}
              </a>
            </li>
          `;
      },
      text: project => project.name_with_namespace,
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
