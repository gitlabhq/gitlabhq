<script>
import { GlAlert } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapMutations } from 'vuex';
import { scrollToElement } from '~/lib/utils/common_utils';
import { HIDE_ERROR } from '../store/mutation_types';
import FilterSortContainer from './filter_sort/filter_sort_container.vue';
import MembersTable from './table/members_table.vue';

export default {
  name: 'MembersApp',
  components: { MembersTable, FilterSortContainer, GlAlert },
  provide() {
    return {
      namespace: this.namespace,
    };
  },
  props: {
    namespace: {
      type: String,
      required: true,
    },
    tabQueryParamValue: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState({
      showError(state) {
        return state[this.namespace].showError;
      },
      errorMessage(state) {
        return state[this.namespace].errorMessage;
      },
    }),
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
      hideError(commit) {
        return commit(`${this.namespace}/${HIDE_ERROR}`);
      },
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
    <members-table :tab-query-param-value="tabQueryParamValue" />
  </div>
</template>
