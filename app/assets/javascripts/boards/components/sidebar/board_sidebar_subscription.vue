<script>
import { mapGetters, mapActions } from 'vuex';
import { GlToggle } from '@gitlab/ui';
import createFlash from '~/flash';
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
      'IssueBoards|An error occurred while setting notifications status.',
    ),
  },
  components: {
    GlToggle,
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    ...mapGetters(['activeIssue', 'projectPathForActiveIssue']),
    notificationText() {
      return this.activeIssue.emailsDisabled
        ? this.$options.i18n.header.subscribeDisabledDescription
        : this.$options.i18n.header.title;
    },
  },
  methods: {
    ...mapActions(['setActiveIssueSubscribed']),
    async handleToggleSubscription() {
      this.loading = true;

      try {
        await this.setActiveIssueSubscribed({
          subscribed: !this.activeIssue.subscribed,
          projectPath: this.projectPathForActiveIssue,
        });
      } catch (error) {
        createFlash({ message: this.$options.i18n.updateSubscribedErrorMessage });
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
      v-if="!activeIssue.emailsDisabled"
      :value="activeIssue.subscribed"
      :is-loading="loading"
      data-testid="notification-subscribe-toggle"
      @change="handleToggleSubscription"
    />
  </div>
</template>
