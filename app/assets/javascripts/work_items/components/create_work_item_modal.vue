<script>
import { GlButton, GlModal, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import { isMetaClick } from '~/lib/utils/common_utils';
import { newWorkItemPath, canRouterNav, getDraftWorkItemType } from '~/work_items/utils';
import {
  NAME_TO_TEXT_LOWERCASE_MAP,
  sprintfWorkItem,
  ROUTES,
  RELATED_ITEM_ID_URL_QUERY_PARAM,
  NAME_TO_ENUM_MAP,
  WORK_ITEM_TYPE_NAME_INCIDENT,
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
    creationContext: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
    fullPath: {
      type: String,
      required: true,
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
    preselectedWorkItemType: {
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
    namespaceFullName: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    const draftWorkItemType = getDraftWorkItemType({
      fullPath: this.fullPath,
      context: this.creationContext,
      relatedItemId: this.relatedItem?.id,
    })?.name;

    return {
      isCreateModalVisible: false,
      isConfirmationModalVisible: false,
      selectedWorkItemTypeName: draftWorkItemType || this.preselectedWorkItemType,
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
    newWorkItemPathQuery() {
      let query = '';
      let previousQueryParam = false;
      // Only add query string if there's a work item type selected
      if (this.selectedWorkItemTypeName && this.useVueRouter) {
        query += previousQueryParam ? '&' : '?';
        // eslint-disable-next-line @gitlab/require-i18n-strings
        query += `type=${NAME_TO_ENUM_MAP[this.selectedWorkItemTypeName]}`;
        previousQueryParam = true;
      }
      if (this.relatedItem) {
        query += previousQueryParam ? '&' : '?';
        query += `${RELATED_ITEM_ID_URL_QUERY_PARAM}=${this.relatedItem.id}`;
      }
      return query;
    },
    newWorkItemPath() {
      return newWorkItemPath({
        fullPath: this.fullPath,
        isGroup: this.isGroup,
        workItemType: this.selectedWorkItemTypeName,
        query: this.newWorkItemPathQuery,
      });
    },
    selectedWorkItemTypeLowercase() {
      return NAME_TO_TEXT_LOWERCASE_MAP[this.selectedWorkItemTypeName];
    },
    newWorkItemButtonText() {
      return this.alwaysShowWorkItemTypeSelect && this.selectedWorkItemTypeName
        ? sprintfWorkItem(s__('WorkItem|New %{workItemType}'), '')
        : this.newWorkItemText;
    },
    newWorkItemText() {
      return sprintfWorkItem(
        s__('WorkItem|New %{workItemType}'),
        this.selectedWorkItemTypeLowercase,
      );
    },
    workItemCreatedText() {
      return sprintfWorkItem(
        s__('WorkItem|%{workItemType} created'),
        this.selectedWorkItemTypeLowercase,
      );
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
    },
    showCreateModal(event) {
      if (!gon?.current_user_id) {
        // If user is signed out, don't show modal, but allow them to click on the button to sign in
        return;
      }

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
              workItem?.workItemType?.name !== WORK_ITEM_TYPE_NAME_INCIDENT &&
              this.$router.getRoutes().some((route) => route.name === 'workItem') &&
              canRouterNav({
                fullPath: this.fullPath,
                isGroup: this.isGroup,
                webUrl: workItem.webUrl,
                issueAsWorkItem: true,
              })
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
      event.preventDefault();

      if (this.useVueRouter) {
        this.$router.push({
          name: ROUTES.new,
          query: {
            [RELATED_ITEM_ID_URL_QUERY_PARAM]: this.relatedItem?.id,
            type: NAME_TO_ENUM_MAP[this.selectedWorkItemTypeName],
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
        <div class="gl-flex gl-w-full gl-items-center gl-justify-between gl-gap-x-2 gl-pr-3">
          <h2 class="modal-title">{{ newWorkItemText }}</h2>
          <gl-button
            v-gl-tooltip.bottom
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
        :creation-context="creationContext"
        :description="description"
        :full-path="fullPath"
        hide-form-title
        modal-button-alignment
        :is-group="isGroup"
        :parent-id="parentId"
        :show-project-selector="showProjectSelector"
        :title="title"
        :preselected-work-item-type="selectedWorkItemTypeName"
        :related-item="relatedItem"
        :should-discard-draft="shouldDiscardDraft"
        :namespace-full-name="namespaceFullName"
        :is-modal="true"
        @changeType="selectedWorkItemTypeName = $event"
        @confirmCancel="handleConfirmCancellation"
        @discardDraft="handleDiscardDraft('createModal')"
        @workItemCreated="handleCreated"
      />
    </gl-modal>
    <create-work-item-cancel-confirmation-modal
      :is-visible="isConfirmationModalVisible"
      :work-item-type="selectedWorkItemTypeName"
      @continueEditing="handleContinueEditing"
      @discardDraft="handleDiscardDraft('confirmModal')"
    />
  </div>
</template>
