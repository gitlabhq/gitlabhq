<script>
import { GlFilteredSearch, GlFilteredSearchToken } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  OPERATORS_IS,
  OPERATORS_IS_NOT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import {
  TIME_RANGE_FILTER_TOKEN_TYPE,
  SERVICE_NAME_FILTER_TOKEN_TYPE,
  OPERATION_FILTER_TOKEN_TYPE,
  TRACE_ID_FILTER_TOKEN_TYPE,
  DURATION_FILTER_TOKEN_TYPE,
} from '../constants';

export default {
  availableTokens: [
    {
      title: s__('Tracing|Time range'),
      icon: 'clock',
      type: TIME_RANGE_FILTER_TOKEN_TYPE,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS,
      unique: true,
      options: [
        { value: 'last1m', title: s__('Tracing|Last 1 minute') },
        { value: 'last15m', title: s__('Tracing|Last 15 minutes') },
        { value: 'last30m', title: s__('Tracing|Last 30 minutes') },
        { value: 'last1h', title: s__('Tracing|Last 1 hour') },
        { value: 'last24h', title: s__('Tracing|Last 24 hours') },
        { value: 'last7d', title: s__('Tracing|Last 7 days') },
        { value: 'last14d', title: s__('Tracing|Last 14 days') },
        { value: 'last30d', title: s__('Tracing|Last 30 days') },
      ],
    },
    {
      title: s__('Tracing|Service'),
      type: SERVICE_NAME_FILTER_TOKEN_TYPE,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS_NOT,
    },
    {
      title: s__('Tracing|Operation'),
      type: OPERATION_FILTER_TOKEN_TYPE,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS_NOT,
    },
    {
      title: s__('Tracing|Trace ID'),
      type: TRACE_ID_FILTER_TOKEN_TYPE,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS_NOT,
    },
    {
      title: s__('Tracing|Duration'),
      type: DURATION_FILTER_TOKEN_TYPE,
      token: GlFilteredSearchToken,
      operators: [
        { value: '>', description: s__('Tracing|longer than') },
        { value: '<', description: s__('Tracing|shorter than') },
      ],
    },
  ],
  components: {
    GlFilteredSearch,
  },
  props: {
    initialFilters: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
};
</script>

<template>
  <div class="vue-filtered-search-bar-container row-content-block gl-border-t-none">
    <gl-filtered-search
      :value="initialFilters"
      terms-as-tokens
      :placeholder="s__('Tracing|Filter Traces')"
      :available-tokens="$options.availableTokens"
      @submit="$emit('submit', $event)"
    />
  </div>
</template>
