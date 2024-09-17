<script>
import { isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { ANY_OPTION, GROUP_DATA, PROJECT_DATA } from '../constants';
import SearchableDropdown from './shared/searchable_dropdown.vue';

export default {
  name: 'GroupFilter',
  i18n: {
    groupFieldLabel: s__('GlobalSearch|Group'),
  },
  components: {
    SearchableDropdown,
  },
  data() {
    return {
      search: '',
      labelId: 'group-filter-dropdown-id',
    };
  },
  computed: {
    ...mapState(['query', 'groups', 'fetchingGroups', 'groupInitialJson', 'useSidebarNavigation']),
    ...mapGetters(['frequentGroups', 'currentScope']),
    selectedGroup() {
      return isEmpty(this.groupInitialJson) ? ANY_OPTION : this.groupInitialJson;
    },
  },
  watch: {
    search() {
      this.debounceSearch();
    },
  },
  created() {
    // This tracks groups searched via the top nav search bar
    if (this.query.nav_source === 'navbar' && this.groupInitialJson?.id) {
      this.setFrequentGroup(this.groupInitialJson);
    }
  },
  methods: {
    ...mapActions(['fetchGroups', 'setFrequentGroup', 'loadFrequentGroups']),
    firstLoad() {
      this.loadFrequentGroups();
      this.fetchGroups();
    },
    handleGroupChange(group) {
      // If group.id is null we are clearing the filter and don't need to store that in LS.
      if (group.id) {
        this.setFrequentGroup(group);
      }

      visitUrl(
        setUrlParams({
          [GROUP_DATA.queryParam]: group.id,
          [PROJECT_DATA.queryParam]: null,
          nav_source: null,
          scope: this.currentScope,
        }),
      );
    },
  },
  GROUP_DATA,
};
</script>

<template>
  <div>
    <h5 :id="labelId" class="gl-mb-2 gl-mt-0 gl-text-sm">
      {{ $options.i18n.groupFieldLabel }}
    </h5>
    <searchable-dropdown
      data-testid="group-filter"
      :header-text="$options.GROUP_DATA.headerText"
      :name="$options.GROUP_DATA.name"
      :loading="fetchingGroups"
      :selected-item="selectedGroup"
      :items="groups"
      :frequent-items="frequentGroups"
      :search-handler="fetchGroups"
      :label-id="labelId"
      @first-open="firstLoad"
      @change="handleGroupChange"
    />
  </div>
</template>
