<script>
import produce from 'immer';
import { debounce, isEmpty, isNull } from 'lodash';
import { GlAvatarLabeled, GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';

import searchUsersQuery from '~/graphql_shared/queries/users_search_all_paginated.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

const USERS_PER_PAGE = 20;

const createUserObject = (user) => ({
  ...user,
  text: user.name,
  username: `@${user.username}`,
  value: user.id,
});

export default {
  name: 'PlaceholderActions',
  components: {
    GlAvatarLabeled,
    GlButton,
    GlCollapsibleListbox,
  },
  props: {
    placeholder: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },

  data() {
    return {
      isLoadingInitial: true,
      isLoadingMore: false,
      search: '',
      selectedUser: null,
    };
  },

  apollo: {
    users: {
      query: searchUsersQuery,
      variables() {
        return {
          ...this.queryVariables,
        };
      },
      result() {
        this.isLoadingInitial = false;
      },
      error() {
        this.onError();
      },
    },
  },

  computed: {
    queryVariables() {
      return {
        first: USERS_PER_PAGE,
        search: this.search,
      };
    },

    hasNextPage() {
      return this.users?.pageInfo?.hasNextPage;
    },

    isLoading() {
      return this.$apollo.queries.users.loading && !this.isLoadingMore;
    },

    userItems() {
      return this.users?.nodes?.map((user) => createUserObject(user));
    },

    dontReassignSelected() {
      return !isNull(this.selectedUser) && isEmpty(this.selectedUser);
    },

    toggleText() {
      if (this.dontReassignSelected) {
        return s__("UserMapping|Don't reassign");
      }

      if (this.selectedUser) {
        return this.selectedUser.username;
      }

      return s__('UserMapping|Select user');
    },

    selectedUserValue() {
      return this.selectedUser?.value;
    },

    confirmText() {
      return this.dontReassignSelected ? __('Confirm') : s__('UserMapping|Reassign');
    },
  },

  created() {
    this.debouncedSetSearch = debounce(this.setSearch, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },

  methods: {
    async loadMoreUsers() {
      if (!this.hasNextPage) return;

      this.isLoadingMore = true;

      try {
        await this.$apollo.queries.users.fetchMore({
          variables: {
            ...this.queryVariables,
            after: this.users.pageInfo?.endCursor,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.users.nodes = [...previousResult.users.nodes, ...draftData.users.nodes];
            });
          },
        });
      } catch (error) {
        this.onError();
      } finally {
        this.isLoadingMore = false;
      }
    },

    onError() {
      createAlert({
        message: __('There was a problem fetching users.'),
      });
    },

    setSearch(searchTerm) {
      this.search = searchTerm;
    },

    onSelect(value) {
      if (value === '') {
        this.selectedUser = {};
        try {
          this.$refs.userSelect.closeAndFocus();
        } catch {
          // ignore when we can't close listbox
        }
      } else {
        this.selectedUser = this.userItems.find((user) => user.value === value);
      }
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-gap-3">
    <gl-collapsible-listbox
      ref="userSelect"
      block
      is-check-centered
      toggle-class="gl-w-28"
      :header-text="s__('UserMapping|Re-assign to')"
      :toggle-text="toggleText"
      :loading="isLoadingInitial"
      :items="userItems"
      :selected="selectedUserValue"
      searchable
      :searching="isLoading"
      infinite-scroll
      :infinite-scroll-loading="isLoadingMore"
      @search="debouncedSetSearch"
      @select="onSelect"
      @bottom-reached="loadMoreUsers"
    >
      <template #list-item="{ item }">
        <gl-avatar-labeled
          shape="circle"
          :size="32"
          :src="item.avatarUrl"
          :label="item.text"
          :sub-label="item.username"
        />
      </template>

      <template #footer>
        <div
          class="gl-border-t-solid gl-border-t-1 gl-border-t-gray-200 gl-flex gl-flex-col !gl-p-2 !gl-pt-0"
        >
          <gl-button
            category="tertiary"
            class="!gl-justify-start gl-mt-2"
            data-testid="dont-reassign-button"
            @click="onSelect('')"
          >
            {{ s__("UserMapping|Don't reassign") }}
          </gl-button>
        </div>
      </template>
    </gl-collapsible-listbox>

    <gl-button variant="confirm" data-testid="confirm-button">{{ confirmText }}</gl-button>
  </div>
</template>
