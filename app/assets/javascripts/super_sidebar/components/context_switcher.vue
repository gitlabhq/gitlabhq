<script>
import * as Sentry from '@sentry/browser';
import { GlSearchBoxByType, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import searchUserProjectsAndGroups from '../graphql/queries/search_user_groups_and_projects.query.graphql';
import { trackContextAccess, formatContextSwitcherItems } from '../utils';
import NavItem from './nav_item.vue';
import ProjectsList from './projects_list.vue';
import GroupsList from './groups_list.vue';

export default {
  i18n: {
    contextNavigation: s__('Navigation|Context navigation'),
    switchTo: s__('Navigation|Switch to...'),
    searchPlaceholder: s__('Navigation|Search your projects or groups'),
    searchingLabel: s__('Navigation|Retrieving search results'),
    searchError: s__('Navigation|There was an error fetching search results.'),
  },
  apollo: {
    groupsAndProjects: {
      query: searchUserProjectsAndGroups,
      manual: true,
      variables() {
        return {
          username: this.username,
          search: this.searchString,
        };
      },
      result(response) {
        this.hasError = false;
        try {
          const {
            data: {
              projects: { nodes: projects },
              user: {
                groups: { nodes: groups },
              },
            },
          } = response;

          this.projects = formatContextSwitcherItems(projects);
          this.groups = formatContextSwitcherItems(groups);
        } catch (e) {
          this.handleError(e);
        }
      },
      error(e) {
        this.handleError(e);
      },
      skip() {
        return !this.searchString;
      },
    },
  },
  components: {
    GlSearchBoxByType,
    GlLoadingIcon,
    GlAlert,
    NavItem,
    ProjectsList,
    GroupsList,
  },
  props: {
    persistentLinks: {
      type: Array,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
    projectsPath: {
      type: String,
      required: true,
    },
    groupsPath: {
      type: String,
      required: true,
    },
    currentContext: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      searchString: '',
      projects: [],
      groups: [],
      hasError: false,
    };
  },
  computed: {
    isSearch() {
      return Boolean(this.searchString);
    },
    isSearching() {
      return this.$apollo.queries.groupsAndProjects.loading;
    },
  },
  created() {
    if (this.currentContext.namespace) {
      trackContextAccess(this.username, this.currentContext);
    }
  },
  methods: {
    /**
     * This needs to be exposed publicly so that we can auto-focus the search input when the parent
     * GlCollapse is shown.
     */
    focusInput() {
      this.$refs['search-box'].focusInput();
    },
    handleError(e) {
      Sentry.captureException(e);
      this.hasError = true;
    },
  },
  DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
};
</script>

<template>
  <div>
    <div class="gl-p-1 gl-border-b gl-border-gray-50 gl-bg-white">
      <gl-search-box-by-type
        ref="search-box"
        v-model="searchString"
        class="context-switcher-search-box"
        :placeholder="$options.i18n.searchPlaceholder"
        :debounce="$options.DEFAULT_DEBOUNCE_AND_THROTTLE_MS"
        borderless
      />
    </div>
    <gl-loading-icon
      v-if="isSearching"
      class="gl-mt-5"
      size="md"
      :label="$options.i18n.searchingLabel"
    />
    <gl-alert v-else-if="hasError" variant="danger" :dismissible="false" class="gl-m-2">
      {{ $options.i18n.searchError }}
    </gl-alert>
    <nav v-else :aria-label="$options.i18n.contextNavigation">
      <ul class="gl-p-0 gl-list-style-none">
        <li v-if="!isSearch">
          <div aria-hidden="true" class="gl-font-weight-bold gl-px-3 gl-py-3">
            {{ $options.i18n.switchTo }}
          </div>
          <ul :aria-label="$options.i18n.switchTo" class="gl-p-0">
            <nav-item
              v-for="item in persistentLinks"
              :key="item.link"
              :item="item"
              :link-classes="{ [item.link_classes]: item.link_classes }"
            />
          </ul>
        </li>
        <projects-list
          :username="username"
          :view-all-link="projectsPath"
          :is-search="isSearch"
          :search-results="projects"
        />
        <groups-list
          :username="username"
          :view-all-link="groupsPath"
          :is-search="isSearch"
          :search-results="groups"
        />
      </ul>
    </nav>
  </div>
</template>
