<script>
import { GlAlert, GlButton, GlIcon, GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { isCurrentUser } from '~/lib/utils/common_utils';
import soloOwnedGroupsQuery from '../graphql/queries/solo_owned_groups.query.graphql';
import { SOLO_OWNED_GROUPS_INITIAL_COUNT, SOLO_OWNED_GROUPS_FETCH_MORE_COUNT } from '../constants';

export default {
  name: 'SoloOwnedGroupsList',
  components: {
    GlAlert,
    GlButton,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
  },
  props: {
    userId: {
      type: [Number, String],
      required: true,
    },
    username: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['change'],
  data() {
    return {
      groups: null,
      hasError: false,
      isLoadingMore: false,
    };
  },
  apollo: {
    groups: {
      query: soloOwnedGroupsQuery,
      fetchPolicy: fetchPolicies.NETWORK_ONLY,
      nextFetchPolicy: fetchPolicies.CACHE_FIRST,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_USER, this.userId),
          first: SOLO_OWNED_GROUPS_INITIAL_COUNT,
        };
      },
      update(data) {
        const groups = data.user?.groups ?? null;

        if (!groups) {
          this.hasError = true;
        }

        return groups;
      },
      error() {
        this.hasError = true;
      },
    },
  },
  computed: {
    isLoading() {
      return !this.groups && !this.hasError;
    },
    count() {
      return this.groups?.count ?? 0;
    },
    alertMessage() {
      if (isCurrentUser(this.userId)) {
        return n__(
          'Organization|You are the sole owner of %{count} group',
          'Organization|You are the sole owner of %{count} groups',
          this.count,
        );
      }

      return n__(
        'Organization|%{username} is the sole owner of %{count} group',
        'Organization|%{username} is the sole owner of %{count} groups',
        this.count,
      );
    },
    hasNextPage() {
      return this.groups.pageInfo.hasNextPage;
    },
    hiddenCount() {
      return this.count - this.groups.nodes.length;
    },
    status() {
      return { loading: this.isLoading, count: this.count, error: this.hasError };
    },
  },
  watch: {
    status: {
      handler(status) {
        this.$emit('change', status);
      },
      immediate: true,
    },
  },
  methods: {
    groupIcon(group) {
      return group.parent ? 'subgroup' : 'group';
    },
    async showMore() {
      this.isLoadingMore = true;

      try {
        await this.$apollo.queries.groups.fetchMore({
          variables: {
            after: this.groups.pageInfo.endCursor,
            first: SOLO_OWNED_GROUPS_FETCH_MORE_COUNT,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            const previousGroups = previousResult.user.groups;
            const newGroups = fetchMoreResult.user?.groups;

            if (!newGroups) {
              this.hasError = true;
              return previousResult;
            }

            return {
              user: {
                ...fetchMoreResult.user,
                groups: {
                  ...newGroups,
                  nodes: [...previousGroups.nodes, ...newGroups.nodes],
                },
              },
            };
          },
        });
      } catch {
        this.hasError = true;
      } finally {
        this.isLoadingMore = false;
      }
    },
  },
};
</script>

<template>
  <gl-loading-icon v-if="isLoading" size="md" class="gl-my-5" />
  <gl-alert v-else-if="hasError" variant="danger" :dismissible="false">
    {{ s__('Organization|An error occurred while loading groups. Please try again.') }}
  </gl-alert>
  <div v-else-if="count">
    <gl-alert
      variant="danger"
      :dismissible="false"
      class="gl-mb-5 !gl-border-transparent"
      data-testid="solo-owned-groups-alert"
    >
      <gl-sprintf :message="alertMessage">
        <template #username
          ><strong>{{ username }}</strong></template
        >
        <template #count>{{ count }}</template>
      </gl-sprintf>
    </gl-alert>
    <ul
      class="gl-border gl-m-0 gl-max-h-31 gl-list-none gl-overflow-y-auto gl-rounded-default gl-p-0 md:gl-max-h-48"
    >
      <li
        v-for="group in groups.nodes"
        :key="group.id"
        class="gl-border-b gl-flex gl-items-center gl-gap-3 gl-px-4 gl-py-3 last:gl-border-b-0"
        data-testid="solo-owned-group"
      >
        <gl-icon :name="groupIcon(group)" variant="subtle" class="gl-shrink-0" />
        <gl-link :href="group.webPath" class="gl-min-w-0 gl-break-anywhere">{{
          group.fullPath
        }}</gl-link>
      </li>
      <li v-if="hasNextPage">
        <gl-button
          category="tertiary"
          block
          :loading="isLoadingMore"
          button-text-classes="gl-flex gl-w-full gl-items-center gl-justify-between"
          data-testid="show-more-groups"
          @click="showMore"
        >
          {{ n__('Organization|+%d more group', 'Organization|+%d more groups', hiddenCount) }}
          <gl-icon name="chevron-down" />
        </gl-button>
      </li>
    </ul>
    <p class="gl-mb-0 gl-mt-5" data-testid="solo-owned-groups-help">
      <slot name="help"></slot>
    </p>
  </div>
</template>
