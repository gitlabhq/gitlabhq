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
      projects: [],
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
  },
  methods: {
    loadProjects() {
      this.loading = true;
      Api.groupProjects(this.groupId, {}, (projects) => {
        this.projects = projects;
        this.loading = false;
      });
    },
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
        data(term, callback) {
          return Api.groupProjects(this.groupId, term, callback);
        },
        text: project => project.name,
      });
    }
  },
  template: `
    <div class="card board-new-issue-form">
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
          <div class="dropdown">
            <button
              @click="loadProjects"
              class="dropdown-menu-toggle wide"
              type="button"
              data-toggle="dropdown"
              aria-expanded="false">
              {{ selectedProjectName }}
              <i class="fa fa-chevron-down" aria-hidden="true"></i>
            </button>
            <div class="dropdown-menu dropdown-menu-selectable dropdown-menu-full-width">
              <loading-icon v-if="loading" />
              <ul>
                <li v-for="project in projects">
                  <a
                    href="#"
                    role="button"
                    :class="{ 'is-active': project.id == selectedProject.id }"
                    @click.prevent="selectedProject = project">
                    {{ project.name }}
                  </a>
                </li>
              </ul>
            </div>
          </div>
        </template>
        <div class="clearfix prepend-top-10">
          <button class="btn btn-success pull-left"
            type="submit"
            :disabled="title === ''"
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
  `,
};
