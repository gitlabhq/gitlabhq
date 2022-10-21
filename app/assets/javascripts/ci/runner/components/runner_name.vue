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
  <span class="gl-font-weight-bold gl-vertical-align-middle"
    >#{{ getIdFromGraphQLId(runner.id) }} ({{ runner.shortSha }})</span
  >
</template>
