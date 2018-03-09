<script>
  /* global ListIssue */

  import $ from 'jquery';
  import _ from 'underscore';
  import eventHub from '../eventhub';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import Api from '../../api';

  export default {
    name: 'BoardProjectSelect',
    components: {
      loadingIcon,
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
        return this.selectedProject.name || 'Select a project';
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
          return Api.groupProjects(this.groupId, term, (projects) => {
            this.loading = false;
            callback(projects);
          });
        },
        renderRow(project) {
          return `
            <li>
              <a href='#' class='dropdown-menu-link' data-project-id="${project.id}" data-project-name="${project.name}">
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
    <label class="label-light prepend-top-10">
      Project
    </label>
    <div
      ref="projectsDropdown"
      class="dropdown"
    >
      <button
        class="dropdown-menu-toggle wide"
        type="button"
        data-toggle="dropdown"
        aria-expanded="false"
      >
        {{ selectedProjectName }}
        <i
          class="fa fa-chevron-down"
          aria-hidden="true"
        >
        </i>
      </button>
      <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
        <div class="dropdown-title">
          <span>Projects</span>
          <button
            aria-label="Close"
            type="button"
            class="dropdown-title-button dropdown-menu-close"
          >
            <i
              aria-hidden="true"
              data-hidden="true"
              class="fa fa-times dropdown-menu-close-icon"
            >
            </i>
          </button>
        </div>
        <div class="dropdown-input">
          <input
            class="dropdown-input-field"
            type="search"
            placeholder="Search projects"
          />
          <i
            aria-hidden="true"
            data-hidden="true"
            class="fa fa-search dropdown-input-search"
          >
          </i>
        </div>
        <div class="dropdown-content"></div>
        <div class="dropdown-loading">
          <loading-icon />
        </div>
      </div>
    </div>
  </div>
</template>
