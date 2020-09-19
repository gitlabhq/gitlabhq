<script>
import { mapGetters } from 'vuex';
import ReleasesPaginationGraphql from './releases_pagination_graphql.vue';
import ReleasesPaginationRest from './releases_pagination_rest.vue';

export default {
  name: 'ReleasesPagination',
  components: { ReleasesPaginationGraphql, ReleasesPaginationRest },
  computed: {
    ...mapGetters(['useGraphQLEndpoint']),
  },
};
</script>

<template>
  <div class="gl-display-flex gl-justify-content-center">
    <releases-pagination-graphql v-if="useGraphQLEndpoint" />
    <releases-pagination-rest v-else />
  </div>
</template>
