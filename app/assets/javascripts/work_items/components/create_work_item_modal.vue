<script>
import { GlButton, GlModal, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { isMetaClick } from '~/lib/utils/common_utils';
import { convertTypeEnumToName, newWorkItemPath } from '~/work_items/utils';
import {
  I18N_NEW_WORK_ITEM_BUTTON_LABEL,
  I18N_WORK_ITEM_CREATED,
  sprintfWorkItem,
  ROUTES,
  RELATED_ITEM_ID_URL_QUERY_PARAM,
  WORK_ITEM_TYPE_NAME_LOWERCASE_MAP,
  WORK_ITEM_TYPE_ENUM_INCIDENT,
} from '../constants';
import CreateWorkItem from './create_work_item.vue';
import CreateWorkItemCancelConfirmationModal from './create_work_item_cancel_confirmation_modal.vue';

export default {
  components: {
    CreateWorkItem,
    CreateWorkItemCancelConfirmationModal,
    GlButton,
    GlModal,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['fullPath'],
  props: {
    allowedWorkItemTypes: {
      type: Array,
      required: false,
      default: () => [],
    },
    alwaysShowWorkItemTypeSelect: {
      type: Boolean,
      required: false,
      default: false,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    hideButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    parentId: {
      type: String,
      required: false,
      default: '',
    },
    showProjectSelector: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
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
    relatedItem: {
      type: Object,
      required: false,
      validator: (i) => i.id && i.type && i.reference && i.webUrl,
      default: null,
    },
  },
  data() {
    return {
      isCreateModalVisible: false,
      isConfirmationModalVisible: false,
      selectedWorkItemTypeName: this.workItemTypeName,
      shouldDiscardDraft: false,
    };
  },
  computed: {
    useVueRouter() {
      return (
        !this.asDropdownItem &&
        this.$router &&
        this.$router.options.routes.some((route) => route.name === 'workItem')
      );
    },
    newWorkItemPath() {
      return newWorkItemPath({
        fullPath: this.fullPath,
        isGroup: this.isGroup,
        workItemTypeName: this.workItemTypeName,
        query: this.relatedItem ? `?${RELATED_ITEM_ID_URL_QUERY_PARAM}=${this.relatedItem.id}` : '',
      });
    },
    selectedWorkItemTypeLowercase() {
      return WORK_ITEM_TYPE_NAME_LOWERCASE_MAP[
        convertTypeEnumToName(this.selectedWorkItemTypeName)
      ];
    },
    newWorkItemButtonText() {
      return this.alwaysShowWorkItemTypeSelect && this.workItemTypeName
        ? sprintfWorkItem(I18N_NEW_WORK_ITEM_BUTTON_LABEL, '')
        : this.newWorkItemText;
    },
    newWorkItemText() {
      return sprintfWorkItem(I18N_NEW_WORK_ITEM_BUTTON_LABEL, this.selectedWorkItemTypeLowercase);
    },
    workItemCreatedText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CREATED, this.selectedWorkItemTypeLowercase);
    },
  },
  watch: {
    visible: {
      immediate: true,
      handler(visible) {
        this.isCreateModalVisible = visible;
      },
    },
  },
  methods: {
    hideCreateModal() {
      this.$emit('hideModal');
      this.isCreateModalVisible = false;
      this.selectedWorkItemTypeName = this.workItemTypeName;
    },
    showCreateModal(event) {
      if (Boolean(event) && isMetaClick(event)) {
        // opening in a new tab
        return;
      }

      // don't follow the link for normal clicks - open in modal
      event?.preventDefault();

      this.isCreateModalVisible = true;
    },
    hideConfirmationModal() {
      this.isConfirmationModalVisible = false;
    },
    showConfirmationModal() {
      this.isConfirmationModalVisible = true;
    },
    /*
     Beginning of the methods for the confirmation modal when enabled

     The confirmation modal is enabled when any form field is
     filled or different from the default value.
    */
    handleConfirmCancellation() {
      this.showConfirmationModal();
    },
    handleContinueEditing() {
      this.shouldDiscardDraft = false;
      this.hideConfirmationModal();
    },
    handleDiscardDraft(modal) {
      this.selectedWorkItemTypeName = this.workItemTypeName;

      if (modal === 'createModal') {
        // This is triggered on the create modal when the user didn't update the form,
        // so we just hide the create modal as there's no draft to discard
        this.hideCreateModal();
      } else {
        // This is triggered on the confirmation modal, so the user updated the form and
        // we want to trigger discard draftfunction on create work item component because
        // the user confirmed it
        this.shouldDiscardDraft = true;
        this.hideConfirmationModal();
        this.hideCreateModal();
      }
    },
    /*
     End of the methods for the confirmation modal when enabled
    */
    handleCreated({ workItem }) {
      this.$toast.show(this.workItemCreatedText, {
        autoHideDelay: 10000,
        action: {
          text: __('View details'),
          onClick: () => {
            // Take incidents to the legacy detail view with a full page load
            if (
              this.useVueRouter &&
              this.selectedWorkItemTypeName !== WORK_ITEM_TYPE_ENUM_INCIDENT
            ) {
              this.$router.push({ name: 'workItem', params: { iid: workItem.iid } });
            } else {
              visitUrl(workItem.webUrl);
            }
          },
        },
      });
      this.$emit('workItemCreated', workItem);
      this.hideCreateModal();
    },
    redirectToNewPage(event) {
      if (isMetaClick(event)) {
        // opening in a new tab
        return;
      }

      event.preventDefault();

      if (this.useVueRouter) {
        this.$router.push({
          name: ROUTES.new,
          query: {
            [RELATED_ITEM_ID_URL_QUERY_PARAM]: this.relatedItem?.id,
            type: this.selectedWorkItemTypeName,
          },
        });
      } else {
        visitUrl(this.newWorkItemPath);
      }
    },
  },
};
</script>

<template>
  <div>
    <template v-if="!hideButton">
      <!-- overriding default slow because using item.action doesn't pass the click event, so can't prevent href nav -->
      <gl-disclosure-dropdown-item v-if="asDropdownItem">
        <!-- using an a instead of gl-link to prevent unwanted underline style when active -->
        <template #default
          ><a class="gl-new-dropdown-item-content" :href="newWorkItemPath" @click="showCreateModal"
            ><span class="gl-new-dropdown-item-text-wrapper">{{ newWorkItemText }}</span></a
          ></template
        >
      </gl-disclosure-dropdown-item>
      <gl-button
        v-else
        category="primary"
        variant="confirm"
        data-testid="new-epic-button"
        :href="newWorkItemPath"
        @click="showCreateModal"
        >{{ newWorkItemButtonText }}
      </gl-button>
    </template>
    <gl-modal
      modal-id="create-work-item-modal"
      modal-class="create-work-item-modal"
      :aria-label="newWorkItemText"
      :title="newWorkItemText"
      body-class="!gl-pb-0"
      :visible="isCreateModalVisible"
      scrollable
      size="lg"
      hide-footer
      @hide="hideCreateModal"
    >
      <template #modal-header>
        <div class="gl-text gl-flex gl-w-full gl-items-center gl-gap-x-2">
          <h2 class="modal-title">{{ newWorkItemText }}</h2>
          <gl-button
            v-gl-tooltip.right
            data-testid="new-work-item-modal-link"
            :href="newWorkItemPath"
            :title="__('Open in full page')"
            category="tertiary"
            icon="maximize"
            size="small"
            :aria-label="__('Open in full page')"
            @click="redirectToNewPage"
          />
        </div>
      </template>
      <create-work-item
        :allowed-work-item-types="allowedWorkItemTypes"
        :always-show-work-item-type-select="alwaysShowWorkItemTypeSelect"
        :description="description"
        hide-form-title
        sticky-form-submit
        :is-group="isGroup"
        :parent-id="parentId"
        :show-project-selector="showProjectSelector"
        :title="title"
        :work-item-type-name="workItemTypeName"
        :related-item="relatedItem"
        :should-discard-draft="shouldDiscardDraft"
        @changeType="selectedWorkItemTypeName = $event"
        @confirmCancel="handleConfirmCancellation"
        @discardDraft="handleDiscardDraft('createModal')"
        @workItemCreated="handleCreated"
      />
    </gl-modal>
    <create-work-item-cancel-confirmation-modal
      :is-visible="isConfirmationModalVisible"
      :work-item-type-name="selectedWorkItemTypeLowercase"
      @continueEditing="handleContinueEditing"
      @discardDraft="handleDiscardDraft('confirmModal')"
    />
  </div>
</template>
