<script>
import * as Sentry from '@sentry/browser';
import { GlSearchBoxByType } from '@gitlab/ui';
import { s__ } from '~/locale';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import searchUserProjectsAndGroups from '../graphql/queries/search_user_groups_and_projects.query.graphql';
import { contextSwitcherItems } from '../mock_data';
import { trackContextAccess, formatContextSwitcherItems } from '../utils';
import NavItem from './nav_item.vue';
import ProjectsList from './projects_list.vue';
import GroupsList from './groups_list.vue';

export default {
  i18n: {
    contextNavigation: s__('Navigation|Context navigation'),
    switchTo: s__('Navigation|Switch to...'),
    searchPlaceholder: s__('Navigation|Search for projects or groups'),
  },
  apollo: {
    groupsAndProjects: {
      query: searchUserProjectsAndGroups,
      debounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
      manual: true,
      variables() {
        return {
          username: this.username,
          search: this.searchString,
        };
      },
      result(response) {
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
          Sentry.captureException(e);
        }
      },
      error(e) {
        Sentry.captureException(e);
      },
      skip() {
        return !this.searchString;
      },
    },
  },
  components: {
    GlSearchBoxByType,
    NavItem,
    ProjectsList,
    GroupsList,
  },
  props: {
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
    };
  },
  computed: {
    isSearch() {
      return Boolean(this.searchString);
    },
  },
  contextSwitcherItems,
  created() {
    if (this.currentContext.namespace) {
      trackContextAccess(this.username, this.currentContext);
    }
  },
};
</script>

<template>
  <div>
    <div class="gl-p-1 gl-border-b gl-border-gray-50 gl-bg-white">
      <gl-search-box-by-type
        v-model="searchString"
        class="context-switcher-search-box"
        :placeholder="$options.i18n.searchPlaceholder"
        borderless
      />
    </div>
    <nav :aria-label="$options.i18n.contextNavigation">
      <ul class="gl-p-0 gl-list-style-none">
        <li v-if="!isSearch">
          <div aria-hidden="true" class="gl-font-weight-bold gl-px-3 gl-py-3">
            {{ $options.i18n.switchTo }}
          </div>
          <ul :aria-label="$options.i18n.switchTo" class="gl-p-0">
            <nav-item :item="$options.contextSwitcherItems.yourWork" />
            <nav-item :item="$options.contextSwitcherItems.explore" />
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
