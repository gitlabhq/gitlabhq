<script>
import { mapState, mapMutations } from 'vuex';
import { GlAlert } from '@gitlab/ui';
import { scrollToElement } from '~/lib/utils/common_utils';
import { HIDE_ERROR } from '../store/mutation_types';
import MembersTable from './table/members_table.vue';
import FilterSortContainer from './filter_sort/filter_sort_container.vue';

export default {
  name: 'MembersApp',
  components: { MembersTable, FilterSortContainer, GlAlert },
  computed: {
    ...mapState(['showError', 'errorMessage']),
  },
  watch: {
    showError(value) {
      if (value) {
        this.$nextTick(() => {
          scrollToElement(this.$refs.errorAlert.$el);
        });
      }
    },
  },
  methods: {
    ...mapMutations({
      hideError: HIDE_ERROR,
    }),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showError" ref="errorAlert" variant="danger" @dismiss="hideError">{{
      errorMessage
    }}</gl-alert>
    <filter-sort-container />
    <members-table />
  </div>
</template>
