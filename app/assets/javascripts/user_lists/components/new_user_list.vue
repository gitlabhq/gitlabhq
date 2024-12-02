<script>
import { GlAlert } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import UserListForm from './user_list_form.vue';

export default {
  components: {
    GlAlert,
    UserListForm,
  },
  inject: ['userListsDocsPath', 'featureFlagsPath'],
  translations: {
    pageTitle: s__('UserLists|New list'),
    createButtonLabel: s__('UserLists|Create'),
  },
  computed: {
    ...mapState(['userList', 'errorMessage']),
    isError() {
      return Array.isArray(this.errorMessage) && this.errorMessage.length > 0;
    },
  },
  methods: {
    ...mapActions(['createUserList', 'dismissErrorAlert']),
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="isError" variant="danger" @dismiss="dismissErrorAlert">
      <ul class="gl-mb-0">
        <li v-for="(message, index) in errorMessage" :key="index">
          {{ message }}
        </li>
      </ul>
    </gl-alert>

    <h3 class="gl-border-1 gl-border-default gl-pb-5 gl-font-bold gl-border-b-solid">
      {{ $options.translations.pageTitle }}
    </h3>

    <user-list-form
      :cancel-path="featureFlagsPath"
      :save-button-label="$options.translations.createButtonLabel"
      :user-lists-docs-path="userListsDocsPath"
      :user-list="userList"
      @submit="createUserList"
    />
  </div>
</template>
