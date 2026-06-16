<script>
import { GlAlert } from '@gitlab/ui';
import Api from '~/api';
import { visitUrl } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { getErrorMessages } from '~/user_lists/store/utils';
import UserListForm from './user_list_form.vue';

export default {
  components: {
    GlAlert,
    UserListForm,
  },
  inject: ['userListsDocsPath', 'featureFlagsPath', 'projectId'],
  translations: {
    pageTitle: s__('UserLists|New list'),
    createButtonLabel: s__('UserLists|Create'),
  },
  data() {
    return {
      userList: { name: '', user_xids: '' },
      errorMessage: [],
    };
  },
  computed: {
    isError() {
      return Array.isArray(this.errorMessage) && this.errorMessage.length > 0;
    },
  },
  methods: {
    dismissErrorAlert() {
      this.errorMessage = [];
    },
    async createUserList(userList) {
      try {
        const { data } = await Api.createFeatureFlagUserList(this.projectId, userList);
        visitUrl(data.path);
      } catch (response) {
        this.errorMessage = getErrorMessages(response);
      }
    },
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
