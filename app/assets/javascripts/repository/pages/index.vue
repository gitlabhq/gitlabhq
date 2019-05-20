<script>
import getRef from '../queries/getRef.graphql';

export default {
  apollo: {
    ref: {
      query: getRef,
    },
  },
  data() {
    return {
      ref: '',
    };
  },
};
</script>

<template>
  <div>
    <router-link :to="{ path: `/tree/${ref}/app` }">
      Go to tree
    </router-link>
  </div>
</template>
