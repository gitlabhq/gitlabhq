<script>
import { GlButton, GlModal } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { I18N_NEW_WORK_ITEM_BUTTON_LABEL, sprintfWorkItem } from '../constants';
import CreateWorkItem from './create_work_item.vue';

export default {
  components: {
    CreateWorkItem,
    GlButton,
    GlModal,
  },
  props: {
    workItemType: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      visible: false,
    };
  },
  computed: {
    newWorkItemText() {
      return sprintfWorkItem(I18N_NEW_WORK_ITEM_BUTTON_LABEL, this.workItemType);
    },
  },
  methods: {
    hideModal() {
      this.visible = false;
    },
    showModal() {
      this.visible = true;
    },
    handleCreation(workItem) {
      visitUrl(workItem.webUrl);
    },
  },
};
</script>

<template>
  <div>
    <gl-button
      category="primary"
      variant="confirm"
      data-testid="new-epic-button"
      @click="showModal"
      >{{ newWorkItemText }}</gl-button
    >
    <gl-modal
      modal-id="create-work-item-modal"
      :visible="visible"
      hide-footer
      no-focus-on-show
      @hide="hideModal"
    >
      <create-work-item
        :work-item-type="workItemType"
        @cancel="hideModal"
        @workItemCreated="handleCreation"
      />
    </gl-modal>
  </div>
</template>
