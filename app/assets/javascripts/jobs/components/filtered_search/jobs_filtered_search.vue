<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { s__ } from '~/locale';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import JobStatusToken from './tokens/job_status_token.vue';

export default {
  tokenTypes: {
    status: 'status',
  },
  components: {
    GlFilteredSearch,
  },
  props: {
    queryString: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    tokens() {
      return [
        {
          type: this.$options.tokenTypes.status,
          icon: 'status',
          title: s__('Jobs|Status'),
          unique: true,
          token: JobStatusToken,
          operators: OPERATORS_IS,
        },
      ];
    },
    filteredSearchValue() {
      if (this.queryString?.statuses) {
        return [
          {
            type: 'status',
            value: {
              data: this.queryString?.statuses,
              operator: '=',
            },
          },
        ];
      }
      return [];
    },
  },
  methods: {
    onSubmit(filters) {
      this.$emit('filterJobsBySearch', filters);
    },
  },
};
</script>

<template>
  <gl-filtered-search
    :placeholder="s__('Jobs|Filter jobs')"
    :available-tokens="tokens"
    :value="filteredSearchValue"
    @submit="onSubmit"
  />
</template>
