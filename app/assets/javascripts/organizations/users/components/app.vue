<script>
import { isEqual } from 'lodash';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import organizationUsersQuery from '../graphql/queries/organization_users.query.graphql';
import organizationUsersIsLastOwnerQuery from '../graphql/queries/organization_users_is_last_owner.query.graphql';
import { ORGANIZATION_USERS_PER_PAGE } from '../constants';
import UsersView from './users_view.vue';

const defaultPagination = {
  first: ORGANIZATION_USERS_PER_PAGE,
  last: null,
  before: '',
  after: '',
};

export default {
  name: 'OrganizationsUsersApp',
  components: {
    UsersView,
  },
  i18n: {
    users: __('Users'),
    loadingPlaceholder: __('Loading'),
    errorMessage: s__(
      'Organization|An error occurred loading the organization users. Please refresh the page to try again.',
    ),
  },
  inject: ['organizationGid'],
  data() {
    return {
      organization: {},
      paginationHistory: [defaultPagination],
      pagination: {
        ...defaultPagination,
      },
    };
  },
  apollo: {
    organization: {
      query: organizationUsersQuery,
      variables() {
        return this.apolloQueryVariables;
      },
      update(data) {
        return data.organization;
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.organization.loading;
    },
    users() {
      return this.organization?.organizationUsers || { nodes: [], pageInfo: {} };
    },
    nodes() {
      return this.users.nodes.map(
        ({ id, badges, accessLevel, userPermissions, user, isLastOwner }) => ({
          ...user,
          gid: id,
          id: getIdFromGraphQLId(user.id),
          badges,
          accessLevel,
          userPermissions,
          email: user.publicEmail,
          isLastOwner,
        }),
      );
    },
    pageInfo() {
      return this.users.pageInfo;
    },
    apolloCache() {
      return this.$apollo.provider.defaultClient.cache;
    },
    apolloQueryVariables() {
      return {
        id: this.organizationGid,
        ...this.pagination,
      };
    },
  },
  methods: {
    setPagination(pagination) {
      this.pagination = pagination;
      this.paginationHistory.push(pagination);
    },
    handlePrevPage() {
      this.setPagination({
        first: null,
        after: '',
        last: ORGANIZATION_USERS_PER_PAGE,
        before: this.pageInfo.startCursor,
      });
    },
    handleNextPage() {
      this.setPagination({
        first: ORGANIZATION_USERS_PER_PAGE,
        after: this.pageInfo.endCursor,
        last: null,
        before: '',
      });
    },
    async onRoleChange() {
      try {
        await this.$apollo.query({
          query: organizationUsersIsLastOwnerQuery,
          variables: this.apolloQueryVariables,
          fetchPolicy: fetchPolicies.NETWORK_ONLY,
        });

        // isLastOwner may have changed on other pages so we need to
        // evict the cache for all cached pages except for current page.
        const cacheId = this.apolloCache.identify(this.organization);
        new Set(this.paginationHistory).forEach((pagination) => {
          if (isEqual(pagination, this.pagination)) {
            return;
          }

          this.apolloCache.evict({
            id: cacheId,
            fieldName: 'organizationUsers',
            args: pagination,
          });
        });
        this.apolloCache.gc();
      } catch (error) {
        Sentry.captureException(error);
        // Failed fetching new data async. Reload entire page to hopefully get fresh results and reset Apollo caches.
        window.location.reload();
      }
    },
  },
};
</script>

<template>
  <section>
    <h1 class="gl-my-4 gl-text-size-h-display">{{ $options.i18n.users }}</h1>
    <users-view
      :users="nodes"
      :loading="loading"
      :page-info="pageInfo"
      @prev="handlePrevPage"
      @next="handleNextPage"
      @role-change="onRoleChange"
    />
  </section>
</template>
