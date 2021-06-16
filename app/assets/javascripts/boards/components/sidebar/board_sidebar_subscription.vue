<script>
import { GlToggle } from '@gitlab/ui';
import { mapGetters, mapActions } from 'vuex';
import { __, s__ } from '~/locale';

export default {
  i18n: {
    header: {
      title: __('Notifications'),
      /* Any change to subscribeDisabledDescription
         must be reflected in app/helpers/notifications_helper.rb */
      subscribeDisabledDescription: __(
        'Notifications have been disabled by the project or group owner',
      ),
    },
    updateSubscribedErrorMessage: s__(
      'IssueBoards|An error occurred while setting notifications status. Please try again.',
    ),
  },
  components: {
    GlToggle,
  },
  inject: ['emailsDisabled'],
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    ...mapGetters(['activeBoardItem', 'projectPathForActiveIssue', 'isEpicBoard']),
    isEmailsDisabled() {
      return this.isEpicBoard ? this.emailsDisabled : this.activeBoardItem.emailsDisabled;
    },
    notificationText() {
      return this.isEmailsDisabled
        ? this.$options.i18n.header.subscribeDisabledDescription
        : this.$options.i18n.header.title;
    },
  },
  methods: {
    ...mapActions(['setActiveItemSubscribed', 'setError']),
    async handleToggleSubscription() {
      this.loading = true;
      try {
        await this.setActiveItemSubscribed({
          subscribed: !this.activeBoardItem.subscribed,
          projectPath: this.projectPathForActiveIssue,
        });
      } catch (error) {
        this.setError({ error, message: this.$options.i18n.updateSubscribedErrorMessage });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div
    class="gl-display-flex gl-align-items-center gl-justify-content-space-between"
    data-testid="sidebar-notifications"
  >
    <span data-testid="notification-header-text"> {{ notificationText }} </span>
    <gl-toggle
      v-if="!isEmailsDisabled"
      :value="activeBoardItem.subscribed"
      :is-loading="loading"
      :label="$options.i18n.header.title"
      label-position="hidden"
      data-testid="notification-subscribe-toggle"
      @change="handleToggleSubscription"
    />
  </div>
</template>
