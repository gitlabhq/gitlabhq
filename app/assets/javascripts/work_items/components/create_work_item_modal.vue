<script>
import { GlButton, GlModal, GlDisclosureDropdownItem } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import {
  I18N_NEW_WORK_ITEM_BUTTON_LABEL,
  I18N_WORK_ITEM_CREATED,
  sprintfWorkItem,
} from '../constants';
import CreateWorkItem from './create_work_item.vue';

export default {
  components: {
    CreateWorkItem,
    GlButton,
    GlModal,
    GlDisclosureDropdownItem,
  },
  props: {
    workItemTypeName: {
      type: String,
      required: false,
      default: null,
    },
    asDropdownItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      visible: false,
    };
  },
  computed: {
    newWorkItemText() {
      return sprintfWorkItem(I18N_NEW_WORK_ITEM_BUTTON_LABEL, this.workItemTypeName);
    },
    workItemCreatedText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CREATED, this.workItemTypeName);
    },
    dropdownItem() {
      return {
        text: this.newWorkItemText,
        action: this.showModal,
      };
    },
  },
  methods: {
    hideModal() {
      this.visible = false;
    },
    showModal() {
      this.visible = true;
    },
    handleCreated(workItem) {
      this.$toast.show(this.workItemCreatedText, {
        action: {
          text: __('View details'),
          onClick: () => {
            visitUrl(workItem.webUrl);
          },
        },
      });
      this.$emit('workItemCreated', workItem);
      this.hideModal();
    },
  },
};
</script>

<template>
  <div>
    <gl-disclosure-dropdown-item v-if="asDropdownItem" :item="dropdownItem" />
    <gl-button
      v-else
      category="primary"
      variant="confirm"
      data-testid="new-epic-button"
      @click="showModal"
      >{{ newWorkItemText }}</gl-button
    >
    <gl-modal
      modal-id="create-work-item-modal"
      :visible="visible"
      :title="newWorkItemText"
      size="lg"
      hide-footer
      no-focus-on-show
      @hide="hideModal"
    >
      <create-work-item
        :work-item-type-name="workItemTypeName"
        hide-form-title
        @cancel="hideModal"
        @workItemCreated="handleCreated"
      />
    </gl-modal>
  </div>
</template>
