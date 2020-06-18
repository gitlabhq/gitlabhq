<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import { REMOVE_TAG_CONFIRMATION_TEXT, REMOVE_TAGS_CONFIRMATION_TEXT } from '../../constants/index';

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  props: {
    itemsToBeDeleted: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    modalAction() {
      return n__(
        'ContainerRegistry|Remove tag',
        'ContainerRegistry|Remove tags',
        this.itemsToBeDeleted.length,
      );
    },
    modalDescription() {
      if (this.itemsToBeDeleted.length > 1) {
        return {
          message: REMOVE_TAGS_CONFIRMATION_TEXT,
          item: this.itemsToBeDeleted.length,
        };
      }
      const [first] = this.itemsToBeDeleted;

      return {
        message: REMOVE_TAG_CONFIRMATION_TEXT,
        item: first?.path,
      };
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
    modal-id="delete-tag-modal"
    ok-variant="danger"
    @ok="$emit('confirmDelete')"
    @cancel="$emit('cancelDelete')"
  >
    <template #modal-title>{{ modalAction }}</template>
    <template #modal-ok>{{ modalAction }}</template>
    <p v-if="modalDescription" data-testid="description">
      <gl-sprintf :message="modalDescription.message">
        <template #item
          ><b>{{ modalDescription.item }}</b></template
        >
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
