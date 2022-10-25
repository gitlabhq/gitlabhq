<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  DELETE_PACKAGE_MODAL_CONTENT_MESSAGE,
  DELETE_PACKAGE_MODAL_TITLE,
  DELETE_PACKAGE_MODAL_ACTION,
} from '~/packages_and_registries/shared/constants';
import { TRACK_CATEGORY } from '~/packages_and_registries/infrastructure_registry/shared/constants';

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    itemToBeDeleted: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    isModalVisible() {
      return Boolean(this.itemToBeDeleted);
    },
    deletePackageName() {
      return this.itemToBeDeleted?.name ?? '';
    },
    deleteModalActionPrimaryProps() {
      return {
        text: this.$options.i18n.modalAction,
        attributes: {
          variant: 'danger',
        },
      };
    },
    deleteModalActionCancelProps() {
      return {
        text: __('Cancel'),
      };
    },
    tracking() {
      return {
        category: TRACK_CATEGORY,
      };
    },
  },
  methods: {
    deleteItemConfirmation() {
      this.$emit('ok');
    },
    onChangeModalVisibility(isVisible) {
      if (!isVisible) this.$emit('cancel');
    },
  },
  i18n: {
    modalTitle: DELETE_PACKAGE_MODAL_TITLE,
    modalDescription: DELETE_PACKAGE_MODAL_CONTENT_MESSAGE,
    modalAction: DELETE_PACKAGE_MODAL_ACTION,
  },
};
</script>

<template>
  <gl-modal
    :visible="isModalVisible"
    size="sm"
    modal-id="confirm-delete-package"
    :title="$options.i18n.modalTitle"
    :action-primary="deleteModalActionPrimaryProps"
    :action-cancel="deleteModalActionCancelProps"
    @ok="deleteItemConfirmation"
    @change="onChangeModalVisibility"
  >
    <template #modal-title>{{ $options.i18n.modalTitle }}</template>
    <gl-sprintf :message="$options.i18n.modalDescription">
      <template #name>
        <strong>{{ deletePackageName }}</strong>
      </template>
    </gl-sprintf>
  </gl-modal>
</template>
