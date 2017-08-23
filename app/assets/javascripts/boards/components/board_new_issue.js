/* global ListIssue */
import eventHub from '../eventhub';
import loadingIcon from '../../vue_shared/components/loading_icon.vue';
import Api from '../../api';

const Store = gl.issueBoards.BoardsStore;

export default {
  name: 'BoardNewIssue',
  props: {
    groupId: {
      type: Number,
      required: false,
      default: 0,
    },
    list: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      title: '',
      loading: true,
      selectedProject: {},
      error: false,
    };
  },
  components: {
    loadingIcon,
  },
  computed: {
    selectedProjectName() {
      return this.selectedProject.name || 'Select a project';
    },
    disabled() {
      if (this.groupId) {
        return this.title === '' || !this.selectedProject.name;
      }
      return this.title === '';
    },
  },
  methods: {
    submit(e) {
      e.preventDefault();
      if (this.title.trim() === '') return Promise.resolve();

      this.error = false;

      const labels = this.list.label ? [this.list.label] : [];
      const issue = new ListIssue({
        title: this.title,
        labels,
        subscribed: true,
        assignees: [],
        project_id: this.selectedProject.id,
      });

      if (Store.state.currentBoard) {
        issue.milestone_id = Store.state.currentBoard.milestone_id;
      }

      eventHub.$emit(`scroll-board-list-${this.list.id}`);
      this.cancel();

      return this.list.newIssue(issue)
        .then(() => {
          // Need this because our jQuery very kindly disables buttons on ALL form submissions
          $(this.$refs.submitButton).enable();

          Store.detail.issue = issue;
          Store.detail.list = this.list;
        })
        .catch(() => {
          // Need this because our jQuery very kindly disables buttons on ALL form submissions
          $(this.$refs.submitButton).enable();

          // Remove the issue
          this.list.removeIssue(issue);

          // Show error message
          this.error = true;
        });
    },
    cancel() {
      this.title = '';
      eventHub.$emit(`hide-issue-form-${this.list.id}`);
    },
  },
  mounted() {
    this.$refs.input.focus();
    if (this.groupId) {
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
    }
  },
  template: `
    <div class="board-new-issue-form">
      <div class="card">
        <form @submit="submit($event)">
          <div class="flash-container"
            v-if="error">
            <div class="flash-alert">
              An error occured. Please try again.
            </div>
          </div>
          <label class="label-light"
            :for="list.id + '-title'">
            Title
          </label>
          <input class="form-control"
            type="text"
            v-model="title"
            ref="input"
            autocomplete="off"
            :id="list.id + '-title'" />
          <template v-if="groupId">
            <label class="label-light prepend-top-10"
              :for="list.id + '-project'">
              Project
            </label>
            <div ref="projectsDropdown" class="dropdown">
              <button
                class="dropdown-menu-toggle wide"
                type="button"
                data-toggle="dropdown"
                aria-expanded="false">
                {{ selectedProjectName }}
                <i class="fa fa-chevron-down" aria-hidden="true"></i>
              </button>
              <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
                <div class="dropdown-title">
                  <span>Projects</span>
                  <button aria-label="Close" type="button" class="dropdown-title-button dropdown-menu-close">
                    <i aria-hidden="true" data-hidden="true" class="fa fa-times dropdown-menu-close-icon"></i>
                  </button>
                </div>
                <div class="dropdown-input">
                  <input class="dropdown-input-field">
                </div>
                <div class="dropdown-content"></div>
                <div class="dropdown-loading">
                  <loading-icon />
                </div>
              </div>
            </div>
          </template>
          <div class="clearfix prepend-top-10">
            <button class="btn btn-success pull-left"
              type="submit"
              :disabled="disabled"
              ref="submit-button">
              Submit issue
            </button>
            <button class="btn btn-default pull-right"
              type="button"
              @click="cancel">
              Cancel
            </button>
          </div>
        </form>
      </div>
    </div>
  `,
};
