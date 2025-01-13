<script>
import { GlButton, GlModal, GlDisclosureDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { isMetaClick } from '~/lib/utils/common_utils';
import { isWorkItemItemValidEnum, newWorkItemPath } from '~/work_items/utils';
import {
  I18N_NEW_WORK_ITEM_BUTTON_LABEL,
  I18N_WORK_ITEM_CREATED,
  sprintfWorkItem,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
  ROUTES,
  RELATED_ITEM_ID_URL_QUERY_PARAM,
} from '../constants';
import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
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
      validator: (i) => i.id && i.type && i.reference,
      default: null,
    },
  },
  data() {
    return {
      isCreateModalVisible: false,
      isConfirmationModalVisible: false,
      shouldDiscardDraft: false,
      workItemTypes: [],
    };
  },
  apollo: {
    workItemTypes: {
      query() {
        return namespaceWorkItemTypesQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          name: this.workItemTypeName,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes ?? [];
      },
      async result() {
        if (!this.workItemTypes || this.workItemTypes.length === 0) {
          return;
        }

        // We need a valid enum of fetching workItemTypes which otherwise causes issues in cache
        if (!isWorkItemItemValidEnum(this.workItemTypeName)) {
          return;
        }
        await setNewWorkItemCache(
          this.fullPath,
          this.workItemTypes[0]?.widgetDefinitions,
          this.workItemTypeName,
          this.workItemTypes[0]?.id,
          this.workItemTypes[0]?.iconName,
        );
      },
      error() {
        this.error = I18N_WORK_ITEM_ERROR_FETCHING_TYPES;
      },
    },
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
    newWorkItemText() {
      return sprintfWorkItem(I18N_NEW_WORK_ITEM_BUTTON_LABEL, this.workItemTypeName);
    },
    workItemCreatedText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CREATED, this.workItemTypeName);
    },
    cancelConfirmationText() {
      return sprintf(
        s__('WorkItem|Are you sure you want to cancel creating this %{workItemType}?'),
        {
          workItemType: this.workItemTypeName.toLocaleLowerCase(),
        },
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
    handleCreated(workItem) {
      this.$toast.show(this.workItemCreatedText, {
        autoHideDelay: 10000,
        action: {
          text: __('View details'),
          onClick: () => {
            if (this.useVueRouter) {
              this.$router.push({ name: 'workItem', params: { iid: workItem.iid } });
            } else {
              visitUrl(workItem.webUrl);
            }
          },
        },
      });
      this.$emit('workItemCreated', workItem);
      if (this.workItemTypes && this.workItemTypes[0] && this.workItemTypeName) {
        setNewWorkItemCache(
          this.fullPath,
          this.workItemTypes[0]?.widgetDefinitions,
          this.workItemTypeName,
          this.workItemTypes[0]?.id,
          this.workItemTypes[0]?.iconName,
        );
      }
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
          query: { [RELATED_ITEM_ID_URL_QUERY_PARAM]: this.relatedItem?.id },
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
        >{{ newWorkItemText }}
      </gl-button>
    </template>
    <gl-modal
      modal-id="create-work-item-modal"
      modal-class="create-work-item-modal"
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
            v-gl-tooltip
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
        @confirmCancel="handleConfirmCancellation"
        @discardDraft="handleDiscardDraft('createModal')"
        @workItemCreated="handleCreated"
      />
    </gl-modal>
    <create-work-item-cancel-confirmation-modal
      :is-visible="isConfirmationModalVisible"
      :work-item-type-name="workItemTypeName"
      @continueEditing="handleContinueEditing"
      @discardDraft="handleDiscardDraft('confirmModal')"
    />
  </div>
</template>
