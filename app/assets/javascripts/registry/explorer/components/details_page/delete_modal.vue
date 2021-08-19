<script>
import { GlModal, GlSprintf, GlFormInput } from '@gitlab/ui';
import { n__ } from '~/locale';
import {
  REMOVE_TAG_CONFIRMATION_TEXT,
  REMOVE_TAGS_CONFIRMATION_TEXT,
  DELETE_IMAGE_CONFIRMATION_TITLE,
  DELETE_IMAGE_CONFIRMATION_TEXT,
} from '../../constants';

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
      projectPath: '',
    };
  },
  computed: {
    imageProjectPath() {
      return this.itemsToBeDeleted[0]?.project?.path;
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
          item: this.imageProjectPath,
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
      return this.deleteImage && this.projectPath !== this.imageProjectPath;
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
    :action-primary="{
      text: __('Delete'),
      attributes: [{ variant: 'danger' }, { disabled: disablePrimaryButton }],
    }"
    :action-cancel="{ text: __('Cancel') }"
    @primary="$emit('confirmDelete')"
    @cancel="$emit('cancelDelete')"
    @change="projectPath = ''"
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
      <gl-form-input v-model="projectPath" />
    </div>
  </gl-modal>
</template>
