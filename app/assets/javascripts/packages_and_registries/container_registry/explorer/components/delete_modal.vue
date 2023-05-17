<script>
import { GlModal, GlSprintf, GlFormInput } from '@gitlab/ui';
import { __, n__ } from '~/locale';
import {
  REMOVE_TAG_CONFIRMATION_TEXT,
  REMOVE_TAGS_CONFIRMATION_TEXT,
  DELETE_IMAGE_CONFIRMATION_TITLE,
  DELETE_IMAGE_CONFIRMATION_TEXT,
} from '../constants';
import { getImageName } from '../utils';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlFormInput,
  },
  props: {
    itemsToBeDeleted: {
      type: Array,
      required: false,
      default: () => [],
    },
    deleteImage: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      inputImageName: '',
    };
  },
  computed: {
    imageName() {
      const [item] = this.itemsToBeDeleted;
      return getImageName(item);
    },
    modalTitle() {
      if (this.deleteImage) {
        return DELETE_IMAGE_CONFIRMATION_TITLE;
      }
      return n__(
        'ContainerRegistry|Remove tag',
        'ContainerRegistry|Remove tags',
        this.itemsToBeDeleted.length,
      );
    },
    modalDescription() {
      if (this.deleteImage) {
        return {
          message: DELETE_IMAGE_CONFIRMATION_TEXT,
          item: this.imageName,
        };
      }
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
    disablePrimaryButton() {
      return this.deleteImage && this.inputImageName !== this.imageName;
    },
    primaryActionProps() {
      return {
        text: __('Delete'),
        attributes: { variant: 'danger', disabled: this.disablePrimaryButton },
      };
    },
  },
  methods: {
    show() {
      this.$refs.deleteModal.show();
    },
  },
  modal: {
    cancelAction: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <gl-modal
    ref="deleteModal"
    modal-id="delete-modal"
    ok-variant="danger"
    size="sm"
    :action-primary="primaryActionProps"
    :action-cancel="$options.modal.cancelAction"
    @primary="$emit('confirmDelete')"
    @cancel="$emit('cancelDelete')"
    @change="inputImageName = ''"
  >
    <template #modal-title>{{ modalTitle }}</template>
    <p v-if="modalDescription" data-testid="description">
      <gl-sprintf :message="modalDescription.message">
        <template #item>
          <b>{{ modalDescription.item }}</b>
        </template>
        <template #code>
          <code>{{ modalDescription.item }}</code>
        </template>
      </gl-sprintf>
    </p>
    <div v-if="deleteImage">
      <gl-form-input v-model="inputImageName" />
    </div>
  </gl-modal>
</template>
