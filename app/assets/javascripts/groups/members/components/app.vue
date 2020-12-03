<script>
import { mapState, mapMutations } from 'vuex';
import { GlAlert } from '@gitlab/ui';
import MembersTable from '~/members/components/table/members_table.vue';
import FilterSortContainer from '~/members/components/filter_sort/filter_sort_container.vue';
import { scrollToElement } from '~/lib/utils/common_utils';
import { HIDE_ERROR } from '~/members/store/mutation_types';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  name: 'GroupMembersApp',
  components: { MembersTable, FilterSortContainer, GlAlert },
  mixins: [glFeatureFlagsMixin()],
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
    <filter-sort-container v-if="glFeatures.groupMembersFilteredSearch" />
    <members-table />
  </div>
</template>
