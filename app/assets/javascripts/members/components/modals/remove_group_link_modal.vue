<script>
import { GlModal, GlSprintf, GlForm } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import csrf from '~/lib/utils/csrf';
import { __, s__, sprintf } from '~/locale';
import { REMOVE_GROUP_LINK_MODAL_ID } from '../../constants';

export default {
  name: 'RemoveGroupLinkModal',
  actionCancel: {
    text: __('Cancel'),
  },
  actionPrimary: {
    text: s__('Members|Remove group'),
    attributes: {
      variant: 'danger',
    },
  },
  csrf,
  i18n: {
    modalBody: s__('Members|Are you sure you want to remove "%{groupName}"?'),
  },
  modalId: REMOVE_GROUP_LINK_MODAL_ID,
  components: { GlModal, GlSprintf, GlForm },
  inject: ['namespace'],
  computed: {
    ...mapState({
      memberPath(state) {
        return state[this.namespace].memberPath;
      },
      groupLinkToRemove(state) {
        return state[this.namespace].groupLinkToRemove;
      },
      removeGroupLinkModalVisible(state) {
        return state[this.namespace].removeGroupLinkModalVisible;
      },
    }),
    groupLinkPath() {
      return this.memberPath.replace(/:id$/, this.groupLinkToRemove?.id);
    },
    groupName() {
      return this.groupLinkToRemove?.sharedWithGroup.fullName;
    },
    modalTitle() {
      return sprintf(s__('Members|Remove "%{groupName}"'), { groupName: this.groupName });
    },
  },
  methods: {
    ...mapActions({
      hideRemoveGroupLinkModal(dispatch) {
        return dispatch(`${this.namespace}/hideRemoveGroupLinkModal`);
      },
    }),
    handlePrimary() {
      this.$refs.form.$el.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    v-bind="$attrs"
    :modal-id="$options.modalId"
    :visible="removeGroupLinkModalVisible"
    :title="modalTitle"
    :action-primary="$options.actionPrimary"
    :action-cancel="$options.actionCancel"
    size="sm"
    data-qa-selector="remove_group_link_modal_content"
    @primary="handlePrimary"
    @hide="hideRemoveGroupLinkModal"
  >
    <gl-form ref="form" :action="groupLinkPath" method="post">
      <p>
        <gl-sprintf :message="$options.i18n.modalBody">
          <template #groupName>{{ groupName }}</template>
        </gl-sprintf>
      </p>

      <input type="hidden" name="_method" value="delete" />
      <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    </gl-form>
  </gl-modal>
</template>
