<script>
import { GlAlert, GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { mapState } from 'vuex';
import { getLocation } from '~/jira_connect/api';
import { __ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import GroupsList from './groups_list.vue';

export default {
  name: 'JiraConnectApp',
  components: {
    GlAlert,
    GlButton,
    GlModal,
    GroupsList,
  },
  directives: {
    GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
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
    ...mapState(['errorMessage']),
    usersPathWithReturnTo() {
      if (this.location) {
        return `${this.usersPath}?return_to=${this.location}`;
      }

      return this.usersPath;
    },
  },
  modal: {
    cancelProps: {
      text: __('Cancel'),
    },
  },
  created() {
    this.setLocation();
  },
  methods: {
    async setLocation() {
      this.location = await getLocation();
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" class="gl-mb-7" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>

    <h2 class="gl-text-center">{{ s__('JiraService|GitLab for Jira Configuration') }}</h2>

    <div
      class="jira-connect-app-body gl-display-flex gl-justify-content-space-between gl-my-7 gl-pb-4 gl-border-b-solid gl-border-b-1 gl-border-b-gray-200"
    >
      <h5 class="gl-align-self-center gl-mb-0" data-testid="new-jira-connect-ui-heading">
        {{ s__('Integrations|Linked namespaces') }}
      </h5>
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
  </div>
</template>
