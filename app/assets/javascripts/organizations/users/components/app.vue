<script>
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { ORGANIZATION_USERS_PER_PAGE } from '~/organizations/constants';
import organizationUsersQuery from '../graphql/organization_users.query.graphql';
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
      users: [],
      pagination: {
        ...defaultPagination,
      },
      pageInfo: {},
    };
  },
  apollo: {
    users: {
      query: organizationUsersQuery,
      variables() {
        return {
          id: this.organizationGid,
          first: this.pagination.first,
          last: this.pagination.last,
          before: this.pagination.before,
          after: this.pagination.after,
        };
      },
      update(data) {
        const { nodes, pageInfo } = data.organization.organizationUsers;
        this.pageInfo = pageInfo;

        return nodes.map(({ badges, user }) => {
          return { ...user, badges, email: user.publicEmail };
        });
      },
      error(error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.users.loading;
    },
  },
  methods: {
    handlePrevPage() {
      this.pagination.before = this.pageInfo.startCursor;
      this.pagination.after = '';
    },
    handleNextPage() {
      this.pagination.before = '';
      this.pagination.after = this.pageInfo.endCursor;
    },
  },
};
</script>

<template>
  <section>
    <h1 class="gl-my-4 gl-font-size-h-display">{{ $options.i18n.users }}</h1>
    <users-view
      :users="users"
      :loading="loading"
      :page-info="pageInfo"
      @prev="handlePrevPage"
      @next="handleNextPage"
    />
  </section>
</template>
