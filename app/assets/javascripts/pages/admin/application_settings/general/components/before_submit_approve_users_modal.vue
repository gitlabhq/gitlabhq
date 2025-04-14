<script>
import { GlModal } from '@gitlab/ui';
import { __, n__, s__ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

export default {
  name: 'ApproveUsersModal',
  components: {
    GlModal,
  },
  expose: ['show', 'hide'],
  inject: ['beforeSubmitHook', 'beforeSubmitHookContexts', 'pendingUserCount'],
  props: {
    id: {
      type: String,
      required: true,
    },
  },
  computed: {
    actionPrimary() {
      return {
        text: n__(
          'ApplicationSettings|Proceed and approve %d user',
          'ApplicationSettings|Proceed and approve %d users',
          this.pendingUserCount,
        ),
        attributes: {
          variant: 'confirm',
        },
      };
    },
    modal() {
      return this.$refs[this.id];
    },
    text() {
      return n__(
        'ApplicationSettings|By changing this setting, you can also automatically approve %d user who is pending approval.',
        'ApplicationSettings|By changing this setting, you can also automatically approve %d users who are pending approval.',
        this.pendingUserCount,
      );
    },
  },
  mounted() {
    this.beforeSubmitHook(this.verifyApproveUsers);
  },
  methods: {
    show() {
      this.modal.show();
    },
    hide() {
      this.modal.hide();
    },
    verifyApproveUsers() {
      const context = this.beforeSubmitHookContexts[this.id];
      if (!context?.shouldPreventSubmit) return false;
      try {
        const shouldPrevent = context.shouldPreventSubmit();
        if (shouldPrevent) this.show();
        return shouldPrevent;
      } catch (error) {
        Sentry.captureException(error, {
          tags: { vue_component: 'before_submit_approve_users_modal' },
        });
        return false;
      }
    },
  },
  modal: {
    actionCancel: {
      text: __('Cancel'),
    },
    actionSecondary: {
      text: s__('ApplicationSettings|Proceed without auto-approval'),
      attributes: {
        category: 'secondary',
        variant: 'confirm',
      },
    },
  },
};
</script>

<template>
  <gl-modal
    :ref="id"
    :modal-id="id"
    :action-cancel="$options.modal.actionCancel"
    :action-primary="actionPrimary"
    :action-secondary="$options.modal.actionSecondary"
    :title="s__('ApplicationSettings|Change setting and approve pending users?')"
    @hide="$emit('hide')"
    @primary="$emit('primary')"
    @secondary="$emit('secondary')"
    >{{ text }}</gl-modal
  >
</template>
