<script>
import { GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { ADD_NAMESPACE_MODAL_ID } from '../../constants';
import GroupsList from './groups_list.vue';

export default {
  components: { GlModal, GroupsList },
  modal: {
    id: ADD_NAMESPACE_MODAL_ID,
    title: s__('JiraConnect|Link groups'),
    cancelProps: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modal.id"
    :title="$options.modal.title"
    :action-cancel="$options.modal.cancelProps"
  >
    <groups-list />
  </gl-modal>
</template>
