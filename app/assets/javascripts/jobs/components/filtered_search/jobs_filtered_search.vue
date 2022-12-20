<script>
import { GlFilteredSearch } from '@gitlab/ui';
import {
  OPERATORS_IS,
  TOKEN_TITLE_STATUS,
  TOKEN_TYPE_STATUS,
} from '~/vue_shared/components/filtered_search_bar/constants';
import JobStatusToken from './tokens/job_status_token.vue';

export default {
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
          type: TOKEN_TYPE_STATUS,
          icon: 'status',
          title: TOKEN_TITLE_STATUS,
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
            type: TOKEN_TYPE_STATUS,
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
