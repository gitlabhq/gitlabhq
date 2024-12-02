<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { s__, sprintf } from '~/locale';
import statuses from '../constants/edit';
import UserListForm from './user_list_form.vue';

export default {
  components: {
    GlAlert,
    GlLoadingIcon,
    UserListForm,
  },
  inject: ['userListsDocsPath'],
  translations: {
    saveButtonLabel: s__('UserLists|Save'),
  },
  computed: {
    ...mapState(['userList', 'status', 'errorMessage']),
    title() {
      return sprintf(s__('UserLists|Edit %{name}'), { name: this.userList?.name });
    },
    isLoading() {
      return this.status === statuses.LOADING;
    },
    isError() {
      return this.status === statuses.ERROR;
    },
    hasUserList() {
      return Boolean(this.userList);
    },
  },
  mounted() {
    this.fetchUserList();
  },
  methods: {
    ...mapActions(['fetchUserList', 'updateUserList', 'dismissErrorAlert']),
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="isError"
      :dismissible="hasUserList"
      variant="danger"
      @dismiss="dismissErrorAlert"
    >
      <ul class="gl-mb-0">
        <li v-for="(message, index) in errorMessage" :key="index">
          {{ message }}
        </li>
      </ul>
    </gl-alert>

    <gl-loading-icon v-if="isLoading" size="xl" />

    <template v-else-if="hasUserList">
      <h3
        data-testid="user-list-title"
        class="gl-border-1 gl-border-default gl-pb-5 gl-font-bold gl-border-b-solid"
      >
        {{ title }}
      </h3>
      <user-list-form
        :cancel-path="userList.path"
        :save-button-label="$options.translations.saveButtonLabel"
        :user-lists-docs-path="userListsDocsPath"
        :user-list="userList"
        @submit="updateUserList"
      />
    </template>
  </div>
</template>
