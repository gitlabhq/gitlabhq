<script>
import { GlFormCheckbox, GlModal } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import csrf from '~/lib/utils/csrf';
import { s__, __ } from '~/locale';

export default {
  actionCancel: {
    text: __('Cancel'),
  },
  csrf,
  components: {
    GlFormCheckbox,
    GlModal,
  },
  data() {
    return {
      modalData: {},
    };
  },
  computed: {
    isAccessRequest() {
      return parseBoolean(this.modalData.isAccessRequest);
    },
    isInvite() {
      return parseBoolean(this.modalData.isInvite);
    },
    isGroupMember() {
      return this.modalData.memberType === 'GroupMember';
    },
    actionText() {
      if (this.isAccessRequest) {
        return __('Deny access request');
      } else if (this.isInvite) {
        return s__('Member|Revoke invite');
      }

      return __('Remove member');
    },
    actionPrimary() {
      return {
        text: this.actionText,
        attributes: {
          variant: 'danger',
        },
      };
    },
    showUnassignIssuablesCheckbox() {
      return !this.isAccessRequest && !this.isInvite;
    },
  },
  mounted() {
    document.addEventListener('click', this.handleClick);
  },
  beforeDestroy() {
    document.removeEventListener('click', this.handleClick);
  },
  methods: {
    handleClick(event) {
      const removeButton = event.target.closest('.js-remove-member-button');
      if (removeButton) {
        this.modalData = removeButton.dataset;
        this.$refs.modal.show();
      }
    },
    submitForm() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="remove-member-modal"
    :action-cancel="$options.actionCancel"
    :action-primary="actionPrimary"
    :title="actionText"
    data-qa-selector="remove_member_modal_content"
    @primary="submitForm"
  >
    <form ref="form" :action="modalData.memberPath" method="post">
      <p data-testid="modal-message">{{ modalData.message }}</p>

      <input ref="method" type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
      <gl-form-checkbox v-if="isGroupMember" name="remove_sub_memberships">
        {{ __('Also remove direct user membership from subgroups and projects') }}
      </gl-form-checkbox>
      <gl-form-checkbox v-if="showUnassignIssuablesCheckbox" name="unassign_issuables">
        {{ __('Also unassign this user from related issues and merge requests') }}
      </gl-form-checkbox>
    </form>
  </gl-modal>
</template>
