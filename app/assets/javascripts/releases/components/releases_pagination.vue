<script>
import ReleasesPaginationGraphql from './releases_pagination_graphql.vue';
import ReleasesPaginationRest from './releases_pagination_rest.vue';

export default {
  name: 'ReleasesPagination',
  components: { ReleasesPaginationGraphql, ReleasesPaginationRest },
  computed: {
    // TODO: Remove the ReleasesPaginationRest component since
    // it is never shown.
    // https://gitlab.com/gitlab-org/gitlab/-/issues/329267
    useGraphQLEndpoint() {
      return true;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-justify-content-center">
    <releases-pagination-graphql v-if="useGraphQLEndpoint" />
    <releases-pagination-rest v-else />
  </div>
</template>
