<script>
import { isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import {
  ANY_OPTION,
  GROUP_DATA,
  PROJECT_DATA,
  INCLUDE_ARCHIVED_FILTER_PARAM,
} from '~/search/sidebar/constants';
import SearchableDropdown from './shared/searchable_dropdown.vue';

export default {
  name: 'ProjectFilter',
  i18n: {
    projectFieldLabel: s__('GlobalSearch|Project'),
  },
  components: {
    SearchableDropdown,
  },
  data() {
    return {
      search: '',
      labelId: 'projects-filter-dropdown-id',
    };
  },
  computed: {
    ...mapState([
      'query',
      'projects',
      'fetchingProjects',
      'projectInitialJson',
      'useSidebarNavigation',
    ]),
    ...mapGetters(['frequentProjects', 'currentScope']),
    selectedProject() {
      return isEmpty(this.projectInitialJson) ? ANY_OPTION : this.projectInitialJson;
    },
  },
  watch: {
    search() {
      this.debounceSearch();
    },
  },
  created() {
    // This tracks projects searched via the top nav search bar
    if (this.query.nav_source === 'navbar' && this.projectInitialJson?.id) {
      this.setFrequentProject(this.projectInitialJson);
    }
  },
  methods: {
    ...mapActions(['fetchProjects', 'setFrequentProject', 'loadFrequentProjects']),
    firstLoad() {
      this.loadFrequentProjects();
      this.fetchProjects();
    },
    handleProjectChange(project) {
      // If project.id is null we are clearing the filter and don't need to store that in LS.
      if (project.id) {
        this.setFrequentProject(project);
      }

      // This determines if we need to update the group filter or not
      const queryParams = {
        ...(project.namespace?.id && { [GROUP_DATA.queryParam]: project.namespace.id }),
        [PROJECT_DATA.queryParam]: project.id,
        nav_source: null,
        scope: this.currentScope,
        [INCLUDE_ARCHIVED_FILTER_PARAM]: null,
      };

      visitUrl(setUrlParams(queryParams));
    },
  },
  PROJECT_DATA,
};
</script>

<template>
  <div>
    <h5 :id="labelId" class="gl-mb-2 gl-mt-0 gl-text-sm">
      {{ $options.i18n.projectFieldLabel }}
    </h5>
    <searchable-dropdown
      data-testid="project-filter"
      :header-text="$options.PROJECT_DATA.headerText"
      :name="$options.PROJECT_DATA.name"
      :loading="fetchingProjects"
      :selected-item="selectedProject"
      :items="projects"
      :frequent-items="frequentProjects"
      :search-handler="fetchProjects"
      :label-id="labelId"
      @first-open="firstLoad"
      @change="handleProjectChange"
    />
  </div>
</template>
