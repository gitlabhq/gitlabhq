<script>
import { GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import {
  DELETE_MODAL_CONTENT,
  DELETE_MODAL_TITLE,
  DELETE_PACKAGES_MODAL_DESCRIPTION,
  DELETE_PACKAGES_MODAL_TITLE,
  DELETE_PACKAGE_MODAL_PRIMARY_ACTION,
  DELETE_PACKAGE_REQUEST_FORWARDING_MODAL_CONTENT,
  DELETE_PACKAGES_REQUEST_FORWARDING_MODAL_CONTENT,
  DELETE_PACKAGE_WITH_REQUEST_FORWARDING_PRIMARY_ACTION,
  DELETE_PACKAGES_WITH_REQUEST_FORWARDING_PRIMARY_ACTION,
  REQUEST_FORWARDING_HELP_PAGE_PATH,
} from '~/packages_and_registries/package_registry/constants';

export default {
  name: 'DeleteModal',
  i18n: {
    DELETE_MODAL_CONTENT,
    DELETE_PACKAGES_MODAL_DESCRIPTION,
  },
  components: {
    GlLink,
    GlModal,
    GlSprintf,
  },
  props: {
    itemsToBeDeleted: {
      type: Array,
      required: true,
    },
    showRequestForwardingContent: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    itemToBeDeleted() {
      if (this.itemsToBeDeleted.length === 1) {
        const [itemToBeDeleted] = this.itemsToBeDeleted;
        return itemToBeDeleted;
      }
      return null;
    },
    title() {
      return this.itemToBeDeleted ? DELETE_MODAL_TITLE : DELETE_PACKAGES_MODAL_TITLE;
    },
    packagesDeletePrimaryActionProps() {
      let text = DELETE_PACKAGE_MODAL_PRIMARY_ACTION;

      if (this.showRequestForwardingContent) {
        if (this.itemToBeDeleted) {
          text = DELETE_PACKAGE_WITH_REQUEST_FORWARDING_PRIMARY_ACTION;
        } else {
          text = DELETE_PACKAGES_WITH_REQUEST_FORWARDING_PRIMARY_ACTION;
        }
      }
      return {
        text,
        attributes: { variant: 'danger', category: 'primary' },
      };
    },
    requestForwardingContentMessage() {
      return this.itemToBeDeleted
        ? DELETE_PACKAGE_REQUEST_FORWARDING_MODAL_CONTENT
        : DELETE_PACKAGES_REQUEST_FORWARDING_MODAL_CONTENT;
    },
  },
  modal: {
    cancelAction: {
      text: __('Cancel'),
    },
  },
  methods: {
    show() {
      this.$refs.deleteModal.show();
    },
  },
  links: {
    REQUEST_FORWARDING_HELP_PAGE_PATH,
  },
};
</script>

<template>
  <gl-modal
    ref="deleteModal"
    size="sm"
    modal-id="delete-packages-modal"
    :action-primary="packagesDeletePrimaryActionProps"
    :action-cancel="$options.modal.cancelAction"
    :title="title"
    @primary="$emit('confirm')"
    @cancel="$emit('cancel')"
  >
    <p v-if="showRequestForwardingContent">
      <gl-sprintf :message="requestForwardingContentMessage">
        <template #docLink="{ content }">
          <gl-link :href="$options.links.REQUEST_FORWARDING_HELP_PAGE_PATH">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p v-else>
      <gl-sprintf v-if="itemToBeDeleted" :message="$options.i18n.DELETE_MODAL_CONTENT">
        <template #version>
          <strong>{{ itemToBeDeleted.version }}</strong>
        </template>

        <template #name>
          <strong>{{ itemToBeDeleted.name }}</strong>
        </template>
      </gl-sprintf>
      <gl-sprintf v-else :message="$options.i18n.DELETE_PACKAGES_MODAL_DESCRIPTION">
        <template #count>
          {{ itemsToBeDeleted.length }}
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
