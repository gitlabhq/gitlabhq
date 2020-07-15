<script>
import {
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
  GlTable,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';

export default {
  name: 'JiraImportForm',
  components: {
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
    GlTable,
  },
  currentUsername: gon.current_username,
  dropdownLabel: __('The GitLab user to which the Jira user %{jiraDisplayName} will be mapped'),
  tableConfig: [
    {
      key: 'jiraDisplayName',
      label: __('Jira display name'),
    },
    {
      key: 'arrow',
      label: '',
    },
    {
      key: 'gitlabUsername',
      label: __('GitLab username'),
    },
  ],
  props: {
    importLabel: {
      type: String,
      required: true,
    },
    isSubmitting: {
      type: Boolean,
      required: true,
    },
    issuesPath: {
      type: String,
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
    value: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      isFetching: false,
      searchTerm: '',
      selectState: null,
      users: [],
    };
  },
  computed: {
    shouldShowNoMatchesFoundText() {
      return !this.isFetching && this.users.length === 0;
    },
  },
  watch: {
    searchTerm: debounce(function debouncedUserSearch() {
      this.searchUsers();
    }, 500),
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
      if (this.value) {
        this.hideValidationError();
        this.$emit('initiateJiraImport', this.value);
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
          data-qa-selector="jira_project_dropdown"
          class="mb-2"
          :options="jiraProjects"
          :state="selectState"
          :value="value"
          @change="$emit('input', $event)"
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

      <p>
        {{
          __(
            `Jira users have been matched with similar GitLab users.
            This can be overwritten by selecting a GitLab user from the dropdown in the "GitLab
            username" column.
            If it wasn't possible to match a Jira user with a GitLab user, the dropdown defaults to
            the user conducting the import.`,
          )
        }}
      </p>

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
