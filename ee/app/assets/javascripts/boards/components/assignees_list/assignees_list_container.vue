<script>
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

import AssigneesListFilter from './assignees_list_filter.vue';
import AssigneesListContent from './assignees_list_content.vue';

export default {
  components: {
    LoadingIcon,
    AssigneesListFilter,
    AssigneesListContent,
  },
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    assignees: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      query: '',
    };
  },
  computed: {
    filteredAssignees() {
      if (!this.query) {
        return this.assignees;
      }

      // fuzzaldrinPlus doesn't support filtering
      // on multiple keys hence we're using plain JS.
      const query = this.query.toLowerCase();
      return this.assignees.filter((assignee) => {
        const name = assignee.name.toLowerCase();
        const username = assignee.username.toLowerCase();

        return name.indexOf(query) > -1 || username.indexOf(query) > -1;
      });
    },
  },
  methods: {
    handleSearch(query) {
      this.query = query;
    },
    handleItemClick(assignee) {
      this.$emit('onItemSelect', assignee);
    },
  },
};
</script>

<template>
  <div class="dropdown-assignees-list">
    <div
      v-if="loading"
      class="dropdown-loading"
    >
      <loading-icon />
    </div>
    <assignees-list-filter
      @onSearchInput="handleSearch"
    />
    <assignees-list-content
      v-if="!loading"
      :assignees="filteredAssignees"
      @onItemSelect="handleItemClick"
    />
  </div>
</template>
