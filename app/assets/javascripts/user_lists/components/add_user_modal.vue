<script>
import { GlModal, GlFormGroup, GlFormTextarea } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ADD_USER_MODAL_ID } from '../constants/show';

export default {
  components: {
    GlFormGroup,
    GlFormTextarea,
    GlModal,
  },
  props: {
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  modalOptions: {
    actionPrimary: {
      text: s__('UserLists|Add'),
      attributes: { 'data-testid': 'confirm-add-user-ids', variant: 'confirm' },
    },
    actionCancel: {
      text: s__('UserLists|Cancel'),
      attributes: { 'data-testid': 'cancel-add-user-ids' },
    },
    modalId: ADD_USER_MODAL_ID,
    static: true,
  },
  translations: {
    title: s__('UserLists|Add users'),
    description: s__(
      'UserLists|Enter a comma separated list of user IDs. These IDs should be the users of the system in which the feature flag is set, not GitLab IDs',
    ),
    userIdsLabel: s__('UserLists|User IDs'),
  },
  data() {
    return {
      userIds: '',
    };
  },
  methods: {
    submitUsers() {
      this.$emit('addUsers', this.userIds);
      this.clearInput();
    },
    clearInput() {
      this.userIds = '';
    },
  },
};
</script>
<template>
  <gl-modal
    v-bind="$options.modalOptions"
    :visible="visible"
    @primary="submitUsers"
    @canceled="clearInput"
  >
    <template #modal-title>
      {{ $options.translations.title }}
    </template>
    <template #default>
      <p data-testid="add-userids-description">{{ $options.translations.description }}</p>
      <gl-form-group label-for="add-user-ids" :label="$options.translations.userIdsLabel">
        <gl-form-textarea id="add-user-ids" v-model="userIds" no-resize />
      </gl-form-group>
    </template>
  </gl-modal>
</template>
