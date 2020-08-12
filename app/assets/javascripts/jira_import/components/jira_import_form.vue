<script>
import {
  GlAlert,
  GlButton,
  GlNewDropdown,
  GlNewDropdownItem,
  GlNewDropdownText,
  GlFormGroup,
  GlFormSelect,
  GlIcon,
  GlLabel,
  GlLoadingIcon,
  GlSearchBoxByType,
  GlSprintf,
  GlTable,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import {
  debounceWait,
  dropdownLabel,
  previousImportsMessage,
  tableConfig,
  userMappingMessage,
} from '../utils/constants';

export default {
  name: 'JiraImportForm',
  components: {
    GlAlert,
    GlButton,
    GlNewDropdown,
    GlNewDropdownItem,
    GlNewDropdownText,
    GlFormGroup,
    GlFormSelect,
    GlIcon,
    GlLabel,
    GlLoadingIcon,
    GlSearchBoxByType,
    GlSprintf,
    GlTable,
  },
  currentUsername: gon.current_username,
  dropdownLabel,
  previousImportsMessage,
  tableConfig,
  userMappingMessage,
  props: {
    isSubmitting: {
      type: Boolean,
      required: true,
    },
    issuesPath: {
      type: String,
      required: true,
    },
    jiraImports: {
      type: Array,
      required: true,
    },
    jiraProjects: {
      type: Array,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    userMappings: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isFetching: false,
      searchTerm: '',
      selectedProject: undefined,
      selectState: null,
      users: [],
    };
  },
  computed: {
    shouldShowNoMatchesFoundText() {
      return !this.isFetching && this.users.length === 0;
    },
    numberOfPreviousImports() {
      return this.jiraImports?.reduce?.(
        (acc, jiraProject) => (jiraProject.jiraProjectKey === this.selectedProject ? acc + 1 : acc),
        0,
      );
    },
    hasPreviousImports() {
      return this.numberOfPreviousImports > 0;
    },
    importLabel() {
      return this.selectedProject
        ? `jira-import::${this.selectedProject}-${this.numberOfPreviousImports + 1}`
        : 'jira-import::KEY-1';
    },
  },
  watch: {
    searchTerm: debounce(function debouncedUserSearch() {
      this.searchUsers();
    }, debounceWait),
  },
  mounted() {
    this.searchUsers()
      .then(data => {
        this.initialUsers = data;
      })
      .catch(() => {});
  },
  methods: {
    searchUsers() {
      const params = {
        active: true,
        project_id: this.projectId,
        search: this.searchTerm,
      };

      this.isFetching = true;

      return axios
        .get('/-/autocomplete/users.json', { params })
        .then(({ data }) => {
          this.users = data;
          return data;
        })
        .finally(() => {
          this.isFetching = false;
        });
    },
    resetDropdown() {
      this.searchTerm = '';
      this.users = this.initialUsers;
    },
    initiateJiraImport(event) {
      event.preventDefault();
      if (this.selectedProject) {
        this.hideValidationError();
        this.$emit('initiateJiraImport', this.selectedProject);
      } else {
        this.showValidationError();
      }
    },
    hideValidationError() {
      this.selectState = null;
    },
    showValidationError() {
      this.selectState = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="hasPreviousImports" variant="warning" :dismissible="false">
      <gl-sprintf :message="$options.previousImportsMessage">
        <template #numberOfPreviousImports>{{ numberOfPreviousImports }}</template>
      </gl-sprintf>
    </gl-alert>

    <h3 class="page-title">{{ __('New Jira import') }}</h3>

    <hr />

    <form @submit="initiateJiraImport">
      <gl-form-group
        class="row align-items-center"
        :invalid-feedback="__('Please select a Jira project')"
        :label="__('Import from')"
        label-cols-sm="2"
        label-for="jira-project-select"
      >
        <gl-form-select
          id="jira-project-select"
          v-model="selectedProject"
          data-qa-selector="jira_project_dropdown"
          class="mb-2"
          :options="jiraProjects"
          :state="selectState"
        />
      </gl-form-group>

      <gl-form-group
        class="row gl-align-items-center gl-mb-6"
        :label="__('Issue label')"
        label-cols-sm="2"
        label-for="jira-project-label"
      >
        <gl-label
          id="jira-project-label"
          class="mb-2"
          background-color="#428BCA"
          :title="importLabel"
          scoped
        />
      </gl-form-group>

      <h4 class="gl-mb-4">{{ __('Jira-GitLab user mapping template') }}</h4>

      <p>{{ $options.userMappingMessage }}</p>

      <gl-table :fields="$options.tableConfig" :items="userMappings" fixed>
        <template #cell(arrow)>
          <gl-icon name="arrow-right" :aria-label="__('Will be mapped to')" />
        </template>
        <template #cell(gitlabUsername)="data">
          <gl-new-dropdown
            :text="data.value || $options.currentUsername"
            class="w-100"
            :aria-label="
              sprintf($options.dropdownLabel, { jiraDisplayName: data.item.jiraDisplayName })
            "
            @hide="resetDropdown"
          >
            <gl-search-box-by-type v-model.trim="searchTerm" class="m-2" />

            <div v-if="isFetching" class="gl-text-center">
              <gl-loading-icon />
            </div>

            <gl-new-dropdown-item
              v-for="user in users"
              v-else
              :key="user.id"
              @click="$emit('updateMapping', data.item.jiraAccountId, user.id, user.username)"
            >
              {{ user.username }} ({{ user.name }})
            </gl-new-dropdown-item>

            <gl-new-dropdown-text v-show="shouldShowNoMatchesFoundText" class="text-secondary">
              {{ __('No matches found') }}
            </gl-new-dropdown-text>
          </gl-new-dropdown>
        </template>
      </gl-table>

      <div class="footer-block row-content-block d-flex justify-content-between">
        <gl-button
          type="submit"
          category="primary"
          variant="success"
          class="js-no-auto-disable"
          :loading="isSubmitting"
          data-qa-selector="jira_issues_import_button"
        >
          {{ __('Continue') }}
        </gl-button>
        <gl-button :href="issuesPath">{{ __('Cancel') }}</gl-button>
      </div>
    </form>
  </div>
</template>
