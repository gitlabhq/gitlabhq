<script>
import { GlModal } from '@gitlab/ui';
import { __, n__ } from '~/locale';
import {
  DELETE_PACKAGES_MODAL_TITLE,
  DELETE_PACKAGE_MODAL_PRIMARY_ACTION,
} from '~/packages_and_registries/package_registry/constants';

export default {
  name: 'DeleteModal',
  i18n: {
    DELETE_PACKAGES_MODAL_TITLE,
  },
  components: {
    GlModal,
  },
  props: {
    itemsToBeDeleted: {
      type: Array,
      required: true,
    },
  },
  computed: {
    description() {
      return n__(
        'PackageRegistry|You are about to delete 1 package. This operation is irreversible.',
        `PackageRegistry|You are about to delete %d packages. This operation is irreversible.`,
        this.itemsToBeDeleted.length,
      );
    },
  },
  modal: {
    packagesDeletePrimaryAction: {
      text: DELETE_PACKAGE_MODAL_PRIMARY_ACTION,
      attributes: [{ variant: 'danger' }, { category: 'primary' }],
    },
    cancelAction: {
      text: __('Cancel'),
    },
  },
  methods: {
    show() {
      this.$refs.deleteModal.show();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="deleteModal"
    size="sm"
    modal-id="delete-packages-modal"
    :action-primary="$options.modal.packagesDeletePrimaryAction"
    :action-cancel="$options.modal.cancelAction"
    :title="$options.i18n.DELETE_PACKAGES_MODAL_TITLE"
    @primary="$emit('confirm')"
    @cancel="$emit('cancel')"
  >
    <span>{{ description }}</span>
  </gl-modal>
</template>
