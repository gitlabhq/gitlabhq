<script>
import { GlAlert, GlButton, GlLink, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { mapState, mapMutations } from 'vuex';
import { retrieveAlert, getLocation } from '~/jira_connect/utils';
import { __ } from '~/locale';
import { SET_ALERT } from '../store/mutation_types';
import GroupsList from './groups_list.vue';
import SubscriptionsList from './subscriptions_list.vue';

export default {
  name: 'JiraConnectApp',
  components: {
    GlAlert,
    GlButton,
    GlLink,
    GlModal,
    GlSprintf,
    GroupsList,
    SubscriptionsList,
  },
  directives: {
    GlModalDirective,
  },
  inject: {
    usersPath: {
      default: '',
    },
  },
  data() {
    return {
      location: '',
    };
  },
  computed: {
    ...mapState(['alert']),
    usersPathWithReturnTo() {
      if (this.location) {
        return `${this.usersPath}?return_to=${this.location}`;
      }

      return this.usersPath;
    },
    shouldShowAlert() {
      return Boolean(this.alert?.message);
    },
  },
  modal: {
    cancelProps: {
      text: __('Cancel'),
    },
  },
  created() {
    this.setInitialAlert();
    this.setLocation();
  },
  methods: {
    ...mapMutations({
      setAlert: SET_ALERT,
    }),
    async setLocation() {
      this.location = await getLocation();
    },
    setInitialAlert() {
      const { linkUrl, title, message, variant } = retrieveAlert() || {};
      this.setAlert({ linkUrl, title, message, variant });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="shouldShowAlert"
      class="gl-mb-7"
      :variant="alert.variant"
      :title="alert.title"
      @dismiss="setAlert"
    >
      <gl-sprintf v-if="alert.linkUrl" :message="alert.message">
        <template #link="{ content }">
          <gl-link :href="alert.linkUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>

      <template v-else>
        {{ alert.message }}
      </template>
    </gl-alert>

    <h2 class="gl-text-center">{{ s__('JiraService|GitLab for Jira Configuration') }}</h2>

    <div class="jira-connect-app-body gl-my-7 gl-px-5 gl-pb-4">
      <div class="gl-display-flex gl-justify-content-end">
        <gl-button
          v-if="usersPath"
          category="primary"
          variant="info"
          class="gl-align-self-center"
          :href="usersPathWithReturnTo"
          target="_blank"
          >{{ s__('Integrations|Sign in to add namespaces') }}</gl-button
        >
        <template v-else>
          <gl-button
            v-gl-modal-directive="'add-namespace-modal'"
            category="primary"
            variant="info"
            class="gl-align-self-center"
            >{{ s__('Integrations|Add namespace') }}</gl-button
          >
          <gl-modal
            modal-id="add-namespace-modal"
            :title="s__('Integrations|Link namespaces')"
            :action-cancel="$options.modal.cancelProps"
          >
            <groups-list />
          </gl-modal>
        </template>
      </div>

      <subscriptions-list />
    </div>
  </div>
</template>
