<script>
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

export default {
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  methods: {
    getIdFromGraphQLId,
  },
};
</script>
<template>
  <span>#{{ getIdFromGraphQLId(runner.id) }} ({{ runner.shortSha }})</span>
</template>
