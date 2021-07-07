<script>
import {
  GlFilteredSearchToken,
  GlAvatar,
  GlFilteredSearchSuggestion,
  GlDropdownDivider,
  GlLoadingIcon,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import Api from '~/api';
import createFlash from '~/flash';
import {
  ANY_TRIGGER_AUTHOR,
  FETCH_AUTHOR_ERROR_MESSAGE,
  FILTER_PIPELINES_SEARCH_DELAY,
} from '../../../constants';

export default {
  anyTriggerAuthor: ANY_TRIGGER_AUTHOR,
  components: {
    GlFilteredSearchToken,
    GlAvatar,
    GlFilteredSearchSuggestion,
    GlDropdownDivider,
    GlLoadingIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      users: [],
      loading: true,
    };
  },
  computed: {
    currentValue() {
      return this.value.data.toLowerCase();
    },
    activeUser() {
      return this.users.find((user) => {
        return user.username.toLowerCase() === this.currentValue;
      });
    },
  },
  created() {
    this.fetchProjectUsers();
  },
  methods: {
    fetchProjectUsers(searchTerm) {
      Api.projectUsers(this.config.projectId, searchTerm)
        .then((users) => {
          this.users = users;
          this.loading = false;
        })
        .catch((err) => {
          createFlash({
            message: FETCH_AUTHOR_ERROR_MESSAGE,
          });
          this.loading = false;
          throw err;
        });
    },
    searchAuthors: debounce(function debounceSearch({ data }) {
      this.fetchProjectUsers(data);
    }, FILTER_PIPELINES_SEARCH_DELAY),
  },
};
</script>

<template>
  <gl-filtered-search-token
    :config="config"
    v-bind="{ ...$props, ...$attrs }"
    v-on="$listeners"
    @input="searchAuthors"
  >
    <template #view="{ inputValue }">
      <gl-avatar
        v-if="activeUser"
        :size="16"
        :src="activeUser.avatar_url"
        shape="circle"
        class="gl-mr-2"
      />
      <span>{{ activeUser ? activeUser.name : inputValue }}</span>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion :value="$options.anyTriggerAuthor">{{
        $options.anyTriggerAuthor
      }}</gl-filtered-search-suggestion>
      <gl-dropdown-divider />

      <gl-loading-icon v-if="loading" size="sm" />
      <template v-else>
        <gl-filtered-search-suggestion
          v-for="user in users"
          :key="user.username"
          :value="user.username"
        >
          <div class="d-flex">
            <gl-avatar :size="32" :src="user.avatar_url" />
            <div>
              <div>{{ user.name }}</div>
              <div>@{{ user.username }}</div>
            </div>
          </div>
        </gl-filtered-search-suggestion>
      </template>
    </template>
  </gl-filtered-search-token>
</template>
