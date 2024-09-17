<script>
import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import searchUsersQuery from '~/graphql_shared/queries/users_search_all.query.graphql';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';

import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';

const USERS_PER_PAGE = 20;

export default {
  components: {
    GlAvatarLabeled,
    GlCollapsibleListbox,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    usersQuery: {
      query: searchUsersQuery,
      variables() {
        return {
          search: this.search,
          first: USERS_PER_PAGE,
        };
      },
      update(data) {
        return data;
      },
      debounce: DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    },
  },
  data() {
    return {
      user: '',
      search: '',
    };
  },
  computed: {
    userId() {
      return getIdFromGraphQLId(this.user);
    },
    users() {
      return [
        { text: __('(no user)'), value: '' },
        ...(this.usersQuery?.users.nodes || []).map((u) => ({
          username: `@${u.username}`,
          avatarUrl: u.avatarUrl,
          text: u.name,
          value: u.id,
        })),
      ];
    },
  },
  methods: {
    clearTransform() {
      // FIXME: workaround for listbox issue
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1986
      const { listbox } = this.$refs;
      if (listbox.querySelector('.dropdown-menu')) {
        listbox.querySelector('.dropdown-menu').style.transform = '';
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-collapsible-listbox
      ref="listbox"
      v-model="user"
      :items="users"
      searchable
      is-check-centered
      :searching="$apollo.loading"
      @click.capture.native="clearTransform"
      @search="search = $event"
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
    </gl-collapsible-listbox>
    <input type="hidden" :name="name" :value="userId" />
  </div>
</template>
