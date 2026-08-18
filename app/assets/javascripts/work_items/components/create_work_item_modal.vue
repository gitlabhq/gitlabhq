<script>
import {
  GlButton,
  GlIcon,
  GlModal,
  GlDisclosureDropdownItem,
  GlTooltipDirective,
  GlToastMixin,
} from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { isMetaClick } from '~/lib/utils/common_utils';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { MR_WORK_ITEM_RELATIONSHIP_TYPES } from '~/sidebar/constants';
import { newWorkItemPath, canRouterNav, getDraftWorkItemType } from '~/work_items/utils';

import {
  RELATED_ITEM_ID_URL_QUERY_PARAM,
  ROUTES,
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
} from '../constants';
import CreateWorkItem from './create_work_item.vue';
import CreateWorkItemCancelConfirmationModal from './create_work_item_cancel_confirmation_modal.vue';

export default {
  name: 'CreateWorkItemModal',
  components: {
    CreateWorkItem,
    CreateWorkItemCancelConfirmationModal,
    GlButton,
    GlIcon,
    GlModal,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin(), GlToastMixin],
  props: {
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
    mergeRequestId: {
      type: String,
      required: false,
      default: null,
    },
    mergeRequestLinkType: {
      type: String,
      required: false,
      default: null,
    },
    mergeRequestTitle: {
      type: String,
      required: false,
      default: '',
    },
    mergeRequestReference: {
      type: String,
      required: false,
      default: '',
    },
    namespaceFullName: {
      type: String,
      required: false,
      default: '',
    },
    isEpicsList: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowAnyNamespace: {
      type: Boolean,
      required: false,
      default: false,
    },
    allowProjectsOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
    createSource: {
      type: String,
      required: false,
      default: null,
    },
    suppressCreatedToast: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['hide-modal', 'work-item-created'],
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
        query += `type=${this.selectedWorkItemTypeName}`;
        previousQueryParam = true;
      }
      if (this.relatedItem) {
        query += previousQueryParam ? '&' : '?';
        query += `${RELATED_ITEM_ID_URL_QUERY_PARAM}=${this.relatedItem.id}`;
        previousQueryParam = true;
      }
      query += previousQueryParam ? '&' : '?';
      query += `initialCreationContext=${this.creationContext}`;
      return query;
    },
    newWorkItemPath() {
      return newWorkItemPath({
        fullPath: this.fullPath,
        isGroup: this.isGroup,
        query: this.newWorkItemPathQuery,
      });
    },
    newWorkItemButtonText() {
      return this.alwaysShowWorkItemTypeSelect && this.selectedWorkItemTypeName
        ? s__('WorkItem|New item')
        : this.newWorkItemText;
    },
    newWorkItemText() {
      return sprintf(s__('WorkItem|New %{workItemType}'), {
        workItemType: this.selectedWorkItemTypeName,
      });
    },
    showMergeRequestRelationshipNote() {
      return Boolean(this.mergeRequestLinkType && this.mergeRequestTitle);
    },
    mergeRequestRelationshipIntro() {
      if (this.mergeRequestLinkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.closing) {
        return s__('WorkItem|Item will be closed by:');
      }
      if (this.mergeRequestLinkType === MR_WORK_ITEM_RELATIONSHIP_TYPES.related) {
        return s__('WorkItem|Item will be related to:');
      }
      return '';
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
      this.$emit('hide-modal');
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
      if (!this.suppressCreatedToast) {
        const createdWorkItemTypeName =
          workItem?.workItemType?.name || this.selectedWorkItemTypeName;
        const workItemCreatedText = sprintf(s__('WorkItem|%{workItemType} created.'), {
          workItemType: createdWorkItemTypeName,
        });

        this.$toast.show(workItemCreatedText, {
          autoHideDelay: 10000,
          action: {
            text: __('View details'),
            href: workItem.webUrl,
            onClick: (e) => {
              e?.preventDefault();
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
                this.$router.push({
                  name: 'workItem',
                  params: {
                    iid: workItem.iid,
                    type: WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
                  },
                });
              } else {
                visitUrl(workItem.webUrl);
              }
            },
          },
        });
      }
      this.$emit('work-item-created', workItem);
      this.hideCreateModal();
    },
    redirectToNewPage(event) {
      event.preventDefault();

      if (this.useVueRouter) {
        this.$router.push({
          name: ROUTES.new,
          query: {
            [RELATED_ITEM_ID_URL_QUERY_PARAM]: this.relatedItem?.id,
            type: this.selectedWorkItemTypeName,
            initialCreationContext: this.creationContext,
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
      <div
        v-if="showMergeRequestRelationshipNote"
        class="gl-mb-5 gl-inline-block gl-rounded-base gl-bg-blue-50 gl-px-4 gl-py-3"
        data-testid="merge-request-relationship-note"
      >
        <span class="gl-text-sm gl-text-subtle">{{ mergeRequestRelationshipIntro }}</span>
        <div class="gl-flex gl-items-start gl-gap-2">
          <gl-icon name="merge-request" class="gl-icon-subtle" />
          <span class="gl-text-sm gl-font-bold">{{ mergeRequestTitle }}</span>
          <span v-if="mergeRequestReference" class="gl-text-sm gl-text-subtle">{{
            mergeRequestReference
          }}</span>
        </div>
      </div>
      <create-work-item
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
        :merge-request-id="mergeRequestId"
        :merge-request-link-type="mergeRequestLinkType"
        :should-discard-draft="shouldDiscardDraft"
        :namespace-full-name="namespaceFullName"
        :is-modal="true"
        :is-epics-list="isEpicsList"
        :allow-any-namespace="allowAnyNamespace"
        :allow-projects-only="allowProjectsOnly"
        :create-source="createSource"
        @changeType="selectedWorkItemTypeName = $event"
        @confirmCancel="handleConfirmCancellation"
        @discardDraft="handleDiscardDraft('createModal')"
        @work-item-created="handleCreated"
      />
    </gl-modal>
    <create-work-item-cancel-confirmation-modal
      :is-visible="isConfirmationModalVisible"
      :work-item-type="selectedWorkItemTypeName || ''"
      @continueEditing="handleContinueEditing"
      @discardDraft="handleDiscardDraft('confirmModal')"
    />
  </div>
</template>
