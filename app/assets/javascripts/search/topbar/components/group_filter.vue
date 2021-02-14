<script>
import { isEmpty } from 'lodash';
import { mapState, mapActions } from 'vuex';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { ANY_OPTION, GROUP_DATA, PROJECT_DATA } from '../constants';
import SearchableDropdown from './searchable_dropdown.vue';

export default {
  name: 'GroupFilter',
  components: {
    SearchableDropdown,
  },
  props: {
    initialData: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    ...mapState(['groups', 'fetchingGroups']),
    selectedGroup() {
      return isEmpty(this.initialData) ? ANY_OPTION : this.initialData;
    },
  },
  methods: {
    ...mapActions(['fetchGroups']),
    handleGroupChange(group) {
      visitUrl(
        setUrlParams({ [GROUP_DATA.queryParam]: group.id, [PROJECT_DATA.queryParam]: null }),
      );
    },
  },
  GROUP_DATA,
};
</script>

<template>
  <searchable-dropdown
    data-testid="group-filter"
    :header-text="$options.GROUP_DATA.headerText"
    :selected-display-value="$options.GROUP_DATA.selectedDisplayValue"
    :items-display-value="$options.GROUP_DATA.itemsDisplayValue"
    :loading="fetchingGroups"
    :selected-item="selectedGroup"
    :items="groups"
    @search="fetchGroups"
    @change="handleGroupChange"
  />
</template>
