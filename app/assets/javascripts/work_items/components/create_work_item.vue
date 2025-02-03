<script>
import {
  GlButton,
  GlAlert,
  GlLink,
  GlLoadingIcon,
  GlFormCheckbox,
  GlFormGroup,
  GlFormSelect,
  GlSprintf,
  GlIcon,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { clearDraft } from '~/lib/utils/autosave';
import { isMetaEnterKeyPair } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { fetchPolicies } from '~/lib/graphql';
import { s__, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { addHierarchyChild, setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { findWidget } from '~/issues/list/utils';
import TitleSuggestions from '~/issues/new/components/title_suggestions.vue';
import {
  getDisplayReference,
  getNewWorkItemAutoSaveKey,
  newWorkItemFullPath,
} from '~/work_items/utils';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import {
  I18N_WORK_ITEM_CREATE_BUTTON_LABEL,
  I18N_WORK_ITEM_ERROR_CREATING,
  I18N_WORK_ITEM_ERROR_FETCHING_TYPES,
  sprintfWorkItem,
  i18n,
  WIDGET_TYPE_ASSIGNEES,
  WIDGET_TYPE_COLOR,
  NEW_WORK_ITEM_IID,
  WIDGET_TYPE_HEALTH_STATUS,
  WIDGET_TYPE_PARTICIPANTS,
  WIDGET_TYPE_DESCRIPTION,
  NEW_WORK_ITEM_GID,
  WIDGET_TYPE_LABELS,
  WIDGET_TYPE_WEIGHT,
  WIDGET_TYPE_START_AND_DUE_DATE,
  WIDGET_TYPE_CRM_CONTACTS,
  WIDGET_TYPE_LINKED_ITEMS,
  WIDGET_TYPE_ITERATION,
  WIDGET_TYPE_MILESTONE,
  DEFAULT_EPIC_COLORS,
  WIDGET_TYPE_HIERARCHY,
  WORK_ITEM_TYPE_NAME_LOWERCASE_MAP,
  WORK_ITEM_TYPE_NAME_MAP,
  WORK_ITEM_TYPE_VALUE_MAP,
} from '../constants';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import updateNewWorkItemMutation from '../graphql/update_new_work_item.mutation.graphql';
import WorkItemProjectsListbox from './work_item_links/work_item_projects_listbox.vue';
import WorkItemTitle from './work_item_title.vue';
import WorkItemDescription from './work_item_description.vue';
import WorkItemAssignees from './work_item_assignees.vue';
import WorkItemLabels from './work_item_labels.vue';
import WorkItemMilestone from './work_item_milestone.vue';
import WorkItemParent from './work_item_parent.vue';
import WorkItemLoading from './work_item_loading.vue';
import WorkItemCrmContacts from './work_item_crm_contacts.vue';

export default {
  components: {
    GlButton,
    GlAlert,
    GlLink,
    GlLoadingIcon,
    GlFormGroup,
    GlFormCheckbox,
    GlFormSelect,
    GlSprintf,
    GlIcon,
    WorkItemDescription,
    WorkItemTitle,
    WorkItemAssignees,
    WorkItemLabels,
    WorkItemMilestone,
    WorkItemLoading,
    WorkItemCrmContacts,
    WorkItemProjectsListbox,
    TitleSuggestions,
    WorkItemParent,
    WorkItemWeight: () => import('ee_component/work_items/components/work_item_weight.vue'),
    WorkItemHealthStatus: () =>
      import('ee_component/work_items/components/work_item_health_status.vue'),
    WorkItemColor: () => import('ee_component/work_items/components/work_item_color.vue'),
    WorkItemRolledupDates: () =>
      import('ee_component/work_items/components/work_item_rolledup_dates.vue'),
    WorkItemIteration: () => import('ee_component/work_items/components/work_item_iteration.vue'),
  },
  inject: ['fullPath', 'groupPath'],
  i18n: {
    suggestionTitle: s__('WorkItem|Similar items'),
    similarWorkItemHelpText: s__(
      'WorkItem|These existing items have a similar title and may represent potential duplicates.',
    ),
    resolveOneThreadText: s__('WorkItem|Creating this %{workItemType} will resolve the thread in'),
    resolveAllThreadsText: s__(
      'WorkItem|Creating this %{workItemType} will resolve all threads in',
    ),
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
    description: {
      type: String,
      required: false,
      default: '',
    },
    hideFormTitle: {
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
    workItemTypeName: {
      type: String,
      required: false,
      default: null,
    },
    stickyFormSubmit: {
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
    shouldDiscardDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isTitleValid: true,
      workItemTitle: this.title || '',
      isConfidential: false,
      isRelatedToItem: true,
      error: null,
      workItemTypes: [],
      selectedProjectFullPath: this.fullPath || null,
      selectedWorkItemTypeId: null,
      loading: false,
      initialLoadingWorkItem: true,
      initialLoadingWorkItemTypes: true,
      showWorkItemTypeSelect: false,
      discussionToResolve: getParameterByName('discussion_to_resolve'),
      mergeRequestToResolveDiscussionsOf: getParameterByName('merge_request_id'),
      numberOfDiscussionsResolved: '',
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.newWorkItemPath,
          iid: NEW_WORK_ITEM_IID,
        };
      },
      skip() {
        return this.skipWorkItemQuery;
      },
      update(data) {
        const title = data?.workspace?.workItem?.title;

        if (this.isTitleFilled(title)) {
          this.updateTitle(title);
        }
        return data?.workspace?.workItem ?? {};
      },
      result() {
        this.initialLoadingWorkItem = false;
      },
      error() {
        this.error = i18n.fetchError;
      },
    },
    workItemTypes: {
      query() {
        return namespaceWorkItemTypesQuery;
      },
      fetchPolicy() {
        return this.workItemTypeName ? fetchPolicies.CACHE_ONLY : fetchPolicies.CACHE_FIRST;
      },
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.workspace?.workItemTypes?.nodes;
      },
      async result() {
        this.initialLoadingWorkItemTypes = false;
        if (!this.workItemTypes?.length) {
          return;
        }

        let workItemDescription = '';
        let workItemTitle = '';
        if (this.mergeRequestToResolveDiscussionsOf) {
          workItemTitle = document.querySelector(
            '.follow_up_work_item .follow-up-title',
          )?.textContent;
          workItemDescription = document.querySelector(
            '.follow_up_work_item .follow-up-description',
          )?.textContent;
        }

        for await (const workItemType of this.workItemTypes) {
          await setNewWorkItemCache(
            this.fullPath,
            workItemType?.widgetDefinitions,
            workItemType.name,
            workItemType.id,
            workItemType.iconName,
            workItemTitle,
            workItemDescription,
          );
        }

        const selectedWorkItemType = this.workItemTypes?.find(
          (workItemType) => WORK_ITEM_TYPE_VALUE_MAP[workItemType.name] === this.workItemTypeName,
        );

        if (selectedWorkItemType) {
          this.selectedWorkItemTypeId = selectedWorkItemType?.id;
        } else {
          this.showWorkItemTypeSelect = true;
        }
      },
      error() {
        this.error = I18N_WORK_ITEM_ERROR_FETCHING_TYPES;
      },
    },
  },
  computed: {
    newWorkItemPath() {
      return newWorkItemFullPath(this.fullPath, this.selectedWorkItemTypeName);
    },
    isLoading() {
      return (
        this.initialLoadingWorkItemTypes || (this.initialLoadingWorkItem && !this.skipWorkItemQuery)
      );
    },
    skipWorkItemQuery() {
      return !this.fullPath || !this.selectedWorkItemTypeName;
    },
    hasWidgets() {
      return this.workItem?.widgets?.length > 0;
    },
    relatedItemReference() {
      return getDisplayReference(this.fullPath, this.relatedItem.reference);
    },
    relatedItemType() {
      return WORK_ITEM_TYPE_NAME_LOWERCASE_MAP[this.relatedItem?.type];
    },
    workItemAssignees() {
      return findWidget(WIDGET_TYPE_ASSIGNEES, this.workItem);
    },
    workItemMilestone() {
      return findWidget(WIDGET_TYPE_MILESTONE, this.workItem);
    },
    workItemLabels() {
      return findWidget(WIDGET_TYPE_LABELS, this.workItem);
    },
    workItemIteration() {
      return findWidget(WIDGET_TYPE_ITERATION, this.workItem);
    },
    workItemWeight() {
      return findWidget(WIDGET_TYPE_WEIGHT, this.workItem);
    },
    workItemHealthStatus() {
      return findWidget(WIDGET_TYPE_HEALTH_STATUS, this.workItem);
    },
    workItemColor() {
      return findWidget(WIDGET_TYPE_COLOR, this.workItem);
    },
    workItemHierarchy() {
      return findWidget(WIDGET_TYPE_HIERARCHY, this.workItem);
    },
    workItemCrmContacts() {
      return findWidget(WIDGET_TYPE_CRM_CONTACTS, this.workItem);
    },
    workItemTypesForSelect() {
      let workItemTypes = this.workItemTypes ?? [];

      if (this.allowedWorkItemTypes.length) {
        workItemTypes = workItemTypes.filter((workItemType) =>
          this.allowedWorkItemTypes.includes(workItemType.name),
        );
      }

      return workItemTypes.map((workItemType) => ({
        value: workItemType.id,
        text: WORK_ITEM_TYPE_NAME_MAP[workItemType.name],
      }));
    },
    selectedWorkItemType() {
      return this.workItemTypes?.find((item) => item.id === this.selectedWorkItemTypeId);
    },
    selectedWorkItemTypeName() {
      return this.selectedWorkItemType?.name;
    },
    selectedWorkItemTypeIconName() {
      return this.selectedWorkItemType?.iconName;
    },
    selectedWorkItemTypeEnum() {
      return WORK_ITEM_TYPE_VALUE_MAP[this.selectedWorkItemTypeName];
    },
    formOptions() {
      const options = [...this.workItemTypesForSelect];
      if (!this.workItemTypeName) {
        options.unshift({ value: null, text: s__('WorkItem|Select type') });
      }
      return options;
    },
    createErrorText() {
      return sprintfWorkItem(I18N_WORK_ITEM_ERROR_CREATING, this.selectedWorkItemTypeName);
    },
    createWorkItemText() {
      return sprintfWorkItem(I18N_WORK_ITEM_CREATE_BUTTON_LABEL, this.selectedWorkItemTypeName);
    },
    makeConfidentialText() {
      return sprintfWorkItem(
        s__(
          'WorkItem|This %{workItemType} is confidential and should only be visible to users having at least the Planner role',
        ),
        this.selectedWorkItemTypeName,
      );
    },
    titleText() {
      return sprintfWorkItem(s__('WorkItem|New %{workItemType}'), this.selectedWorkItemTypeName);
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    workItemType() {
      return this.workItem?.workItemType?.name;
    },
    workItemParticipantNodes() {
      return this.workItemParticipants?.participants?.nodes ?? [];
    },
    workItemParticipants() {
      return findWidget(WIDGET_TYPE_PARTICIPANTS, this.workItem);
    },
    workItemAssigneeIds() {
      const assigneesWidget = findWidget(WIDGET_TYPE_ASSIGNEES, this.workItem);
      return assigneesWidget?.assignees?.nodes?.map((assignee) => assignee.id) || [];
    },
    workItemLabelIds() {
      const labelsWidget = findWidget(WIDGET_TYPE_LABELS, this.workItem);
      return labelsWidget?.labels?.nodes?.map((label) => label.id) || [];
    },
    workItemWeightValue() {
      const weightWidget = findWidget(WIDGET_TYPE_WEIGHT, this.workItem);
      return weightWidget?.weight ?? null;
    },
    workItemMilestoneId() {
      return this.workItemMilestone?.milestone?.id || null;
    },
    workItemCrmContactIds() {
      return this.workItemCrmContacts?.contacts?.nodes?.map((item) => item.id) || [];
    },
    workItemParent() {
      return this.workItemHierarchy?.parent || null;
    },
    workItemColorValue() {
      const colorWidget = findWidget(WIDGET_TYPE_COLOR, this.workItem);
      return colorWidget?.color || '';
    },
    workItemHealthStatusValue() {
      const healthStatusWidget = findWidget(WIDGET_TYPE_HEALTH_STATUS, this.workItem);
      return healthStatusWidget?.healthStatus || null;
    },
    workItemAuthor() {
      return this.workItem?.author;
    },
    workItemDescription() {
      const descriptionWidget = findWidget(WIDGET_TYPE_DESCRIPTION, this.workItem);
      return descriptionWidget?.description || this.description;
    },
    workItemStartAndDueDate() {
      return findWidget(WIDGET_TYPE_START_AND_DUE_DATE, this.workItem);
    },
    workItemIterationId() {
      return this.workItemIteration?.iteration?.id;
    },
    workItemId() {
      return this.workItem?.id;
    },
    workItemIid() {
      return this.workItem?.iid;
    },
    shouldIncludeRelatedItem() {
      return (
        this.isWidgetSupported(WIDGET_TYPE_LINKED_ITEMS) &&
        this.isRelatedToItem &&
        this.relatedItem?.id
      );
    },
    resolvingMRDiscussionLink() {
      return document.querySelector('.follow_up_work_item_details span.note-link a')?.href || '';
    },
    resolvingMRDiscussionLinkText() {
      return document.querySelector('.follow_up_work_item_details span.note-link a')?.text || '';
    },
    createWorkItemWarning() {
      const warning =
        this.numberOfDiscussionsResolved === '1'
          ? this.$options.i18n.resolveOneThreadText
          : this.$options.i18n.resolveAllThreadsText;
      return sprintf(warning, {
        workItemType: this.selectedWorkItemTypeName,
      });
    },
    isFormFilled() {
      const isTitleFilled = Boolean(this.workItemTitle.trim());
      const isDescriptionFilled = Boolean(this.workItemDescription.trim());
      const defaultColorValue = DEFAULT_EPIC_COLORS;

      return (
        isTitleFilled ||
        isDescriptionFilled ||
        this.workItemAssigneeIds.length > 0 ||
        this.workItemLabelIds.length > 0 ||
        this.workItemCrmContactIds.length > 0 ||
        (Boolean(this.workItemColorValue) && this.workItemColorValue !== defaultColorValue) ||
        Boolean(this.workItemHealthStatusValue) ||
        Boolean(this.workItemDueDateFixed) ||
        Boolean(this.workItemStartDateFixed) ||
        Boolean(this.workItemDueDateIsFixed) ||
        Boolean(this.workItemStartDateIsFixed) ||
        Boolean(this.workItemIterationId)
      );
    },
  },
  watch: {
    shouldDiscardDraft: {
      immediate: true,
      handler(shouldDiscardDraft) {
        // If this component is rendered in the create modal and user added data,
        // we need to track the button clicked on the confirmation modal (another modal)
        if (shouldDiscardDraft) {
          this.handleDiscardDraft();
        }
      },
    },
    /*
      Only needed for the cancellation confirmation modal
      when creating a work item in the project route,
      as you can choose the work item type in the dropdown
    */
    selectedWorkItemTypeName(newValue) {
      this.$emit('updateType', newValue);
    },
  },
  mounted() {
    // We need this event listener in the document because when
    // updating widgets, the form may no be in focus and triggering
    // a keyboard event in the form won't get caught
    document.addEventListener('keydown', this.handleKeydown);

    this.setNumberOfDiscussionsResolved();
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleKeydown);
  },
  methods: {
    handleKeydown(e) {
      if (isMetaEnterKeyPair(e)) {
        this.createWorkItem();
      }
    },
    isTitleFilled(newValue) {
      const title = newValue ?? this.workItemTitle;
      return Boolean(String(title).trim());
    },
    updateTitle(newValue) {
      this.workItemTitle = newValue;
    },
    isWidgetSupported(widgetType) {
      const widgetDefinitions =
        this.selectedWorkItemType?.widgetDefinitions?.flatMap((i) => i.type) || [];
      return widgetDefinitions.indexOf(widgetType) !== -1;
    },
    validate(newValue) {
      this.isTitleValid = this.isTitleFilled(newValue);
    },
    setNumberOfDiscussionsResolved() {
      if (this.discussionToResolve || this.mergeRequestToResolveDiscussionsOf) {
        this.numberOfDiscussionsResolved =
          this.discussionToResolve && this.mergeRequestToResolveDiscussionsOf ? '1' : 'all';
      }
    },
    async updateDraftData(type, value) {
      if (type === 'title') {
        this.workItemTitle = value;
      }

      try {
        this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              fullPath: this.fullPath,
              workItemType: this.selectedWorkItemTypeName || this.workItemTypeName,
              [type]: value,
            },
          },
        });
      } catch {
        this.error = this.createErrorText;
        Sentry.captureException(this.error);
      }
    },
    async createWorkItem() {
      this.validate();

      if (!this.isTitleValid) {
        return;
      }

      this.loading = true;

      const workItemCreateInput = {
        title: this.workItemTitle,
        workItemTypeId: this.selectedWorkItemTypeId,
        namespacePath: this.selectedProjectFullPath || this.fullPath,
        confidential: this.workItem.confidential,
        descriptionWidget: {
          description: this.workItemDescription || '',
        },
      };

      if (this.discussionToResolve || this.mergeRequestToResolveDiscussionsOf) {
        workItemCreateInput.discussionsToResolve = {
          discussionId: this.discussionToResolve,
          noteableId: convertToGraphQLId(
            TYPENAME_MERGE_REQUEST,
            this.mergeRequestToResolveDiscussionsOf,
          ),
        };
      }

      // TODO , we can move this to util, currently objectives with other widgets not being supported is causing issues

      if (this.isWidgetSupported(WIDGET_TYPE_COLOR)) {
        workItemCreateInput.colorWidget = {
          color: this.workItemColorValue,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_ASSIGNEES)) {
        workItemCreateInput.assigneesWidget = {
          assigneeIds: this.workItemAssigneeIds,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_HEALTH_STATUS)) {
        workItemCreateInput.healthStatusWidget = {
          healthStatus: this.workItemHealthStatusValue,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_LABELS)) {
        workItemCreateInput.labelsWidget = {
          labelIds: this.workItemLabelIds,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_ITERATION)) {
        workItemCreateInput.iterationWidget = {
          iterationId: this.workItemIterationId,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_WEIGHT)) {
        workItemCreateInput.weightWidget = {
          weight: this.workItemWeightValue,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_MILESTONE)) {
        workItemCreateInput.milestoneWidget = {
          milestoneId: this.workItemMilestoneId,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_START_AND_DUE_DATE)) {
        workItemCreateInput.startAndDueDateWidget = {
          isFixed: this.workItemStartAndDueDate.isFixed,
          startDate: this.workItemStartAndDueDate.startDate,
          dueDate: this.workItemStartAndDueDate.dueDate,
        };
      }

      if (this.isWidgetSupported(WIDGET_TYPE_CRM_CONTACTS)) {
        workItemCreateInput.crmContactsWidget = {
          contactIds: this.workItemCrmContactIds,
        };
      }

      if (this.shouldIncludeRelatedItem) {
        workItemCreateInput.linkedItemsWidget = {
          workItemsIds: [this.relatedItem.id],
        };
      }

      if (
        this.parentId ||
        (this.isWidgetSupported(WIDGET_TYPE_HIERARCHY) && this.workItemParent?.id)
      ) {
        workItemCreateInput.hierarchyWidget = {
          parentId: this.workItemParent?.id ?? this.parentId,
        };
      }

      try {
        const { data } = await this.$apollo.mutate({
          mutation: createWorkItemMutation,
          variables: {
            input: {
              ...workItemCreateInput,
            },
          },
          update: (store, { data: { workItemCreate } }) => {
            const { workItem } = workItemCreate;

            if (
              this.parentId ||
              (this.isWidgetSupported(WIDGET_TYPE_HIERARCHY) && this.workItemParent?.id)
            ) {
              addHierarchyChild({
                cache: store,
                id: this.workItemParent?.id ?? this.parentId,
                workItem,
              });
            }
          },
        });

        // We can get user-facing errors here. Show them in page alert
        // because if we're in a modal the modal closes after submission.
        if (data.workItemCreate.errors.length) {
          createAlert({
            message: data.workItemCreate.errors.join(' '),
            error: data.workItemCreate.errors,
            captureError: true,
          });
        }

        this.$emit('workItemCreated', {
          workItem: data.workItemCreate.workItem,
          numberOfDiscussionsResolved: this.numberOfDiscussionsResolved,
        });

        const workItemTypeName = this.selectedWorkItemTypeName || this.workItemTypeName;
        const autosaveKey = getNewWorkItemAutoSaveKey(this.fullPath, workItemTypeName);
        clearDraft(autosaveKey);
      } catch {
        this.error = this.createErrorText;
        this.loading = false;
      }
    },
    handleCancelClick() {
      /*
      If any form field is filled or has a non-default value, ask user to confirm
      if they want to discard the draft
    */
      if (this.isFormFilled) {
        this.$emit('confirmCancel');
      } else {
        this.$emit('discardDraft');
        this.handleDiscardDraft();
      }
    },
    handleDiscardDraft() {
      const workItemTypeName = this.selectedWorkItemTypeName || this.workItemTypeName;
      const autosaveKey = getNewWorkItemAutoSaveKey(this.fullPath, workItemTypeName);
      clearDraft(autosaveKey);

      const selectedWorkItemWidgets = this.selectedWorkItemType?.widgetDefinitions || [];

      setNewWorkItemCache(
        this.fullPath,
        selectedWorkItemWidgets,
        this.selectedWorkItemTypeName,
        this.selectedWorkItemTypeId,
        this.selectedWorkItemTypeIconName,
      );
    },
  },
  NEW_WORK_ITEM_IID,
  NEW_WORK_ITEM_GID,
};
</script>

<template>
  <form @submit.prevent="createWorkItem">
    <work-item-loading v-if="isLoading" />
    <template v-else>
      <gl-alert v-if="error" class="gl-mb-3" variant="danger" @dismiss="error = null">
        {{ error }}
      </gl-alert>
      <h1 v-if="!hideFormTitle" class="page-title gl-text-xl gl-pb-5">{{ titleText }}</h1>
      <div class="gl-flex gl-items-center gl-gap-4">
        <gl-form-group
          v-if="showProjectSelector"
          class="gl-max-w-26 gl-flex-grow"
          :label="__('Project')"
        >
          <work-item-projects-listbox
            v-model="selectedProjectFullPath"
            :full-path="fullPath"
            :is-group="isGroup"
          />
        </gl-form-group>

        <gl-loading-icon v-if="$apollo.queries.workItemTypes.loading" size="lg" />
        <gl-form-group
          v-else-if="showWorkItemTypeSelect || alwaysShowWorkItemTypeSelect"
          class="gl-max-w-26 gl-flex-grow"
          :label="__('Type')"
          label-for="work-item-type"
        >
          <gl-form-select
            id="work-item-type"
            v-model="selectedWorkItemTypeId"
            data-testid="work-item-types-select"
            :options="formOptions"
            @change="$emit('changeType', selectedWorkItemTypeEnum)"
          />
        </gl-form-group>
      </div>
      <div v-if="selectedWorkItemTypeId" data-testid="create-work-item">
        <work-item-title
          ref="title"
          data-testid="title-input"
          is-editing
          :is-valid="isTitleValid"
          :title="workItemTitle"
          @updateDraft="updateDraftData('title', $event)"
        />
        <title-suggestions
          :project-path="fullPath"
          :search="workItemTitle"
          :help-text="$options.i18n.similarWorkItemHelpText"
          :title="$options.i18n.suggestionTitle"
        />
        <div data-testid="work-item-overview" class="work-item-overview">
          <section>
            <work-item-description
              edit-mode
              :autofocus="false"
              :description="description"
              :full-path="fullPath"
              :show-buttons-below-field="false"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-type-name="selectedWorkItemTypeName"
              @error="updateError = $event"
              @updateDraft="updateDraftData('description', $event)"
            />
            <div v-if="numberOfDiscussionsResolved && resolvingMRDiscussionLink" class="gl-mb-4">
              <gl-icon class="gl-mr-2" name="information-o" />
              {{ createWorkItemWarning }}
              <gl-link :href="resolvingMRDiscussionLink">{{
                resolvingMRDiscussionLinkText
              }}</gl-link>
            </div>
            <gl-form-checkbox
              id="work-item-confidential"
              v-model="isConfidential"
              data-testid="confidential-checkbox"
              @change="updateDraftData('confidential', $event)"
            >
              {{ makeConfidentialText }}
            </gl-form-checkbox>
            <gl-form-checkbox
              v-if="relatedItem"
              id="work-item-relates-to"
              v-model="isRelatedToItem"
              class="gl-mt-3"
              data-testid="relates-to-checkbox"
            >
              <gl-sprintf
                :message="
                  s__('WorkItem|Mark this item as related to: %{workItemType} %{workItemReference}')
                "
              >
                <template #workItemType>
                  {{ relatedItemType }}
                </template>
                <template #workItemReference>
                  <gl-link :href="relatedItem.webUrl">{{ relatedItemReference }}</gl-link>
                </template>
              </gl-sprintf>
            </gl-form-checkbox>
          </section>
          <aside
            v-if="hasWidgets"
            data-testid="work-item-overview-right-sidebar"
            class="work-item-overview-right-sidebar gl-px-3"
            :class="{ 'is-modal': true }"
          >
            <work-item-assignees
              v-if="workItemAssignees"
              class="js-assignee work-item-attributes-item"
              :can-update="canUpdate"
              :full-path="fullPath"
              :is-group="isGroup"
              :work-item-id="workItemId"
              :assignees="workItemAssignees.assignees.nodes"
              :participants="workItemParticipantNodes"
              :work-item-author="workItemAuthor"
              :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
              :work-item-type="selectedWorkItemTypeName"
              :can-invite-members="workItemAssignees.canInviteMembers"
              @error="$emit('error', $event)"
            />
            <work-item-labels
              v-if="workItemLabels"
              class="js-labels work-item-attributes-item"
              :can-update="canUpdate"
              :full-path="fullPath"
              :is-group="isGroup"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-type="selectedWorkItemTypeName"
              @error="$emit('error', $event)"
            />
            <work-item-iteration
              v-if="workItemIteration"
              class="work-item-attributes-item"
              :full-path="fullPath"
              :is-group="isGroup"
              :iteration="workItemIteration.iteration"
              :can-update="canUpdate"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-type="selectedWorkItemTypeName"
              @error="$emit('error', $event)"
            />
            <work-item-milestone
              v-if="workItemMilestone"
              class="work-item-attributes-item"
              :is-group="isGroup"
              :full-path="fullPath"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-milestone="workItemMilestone.milestone"
              :work-item-type="selectedWorkItemTypeName"
              :can-update="canUpdate"
              @error="$emit('error', $event)"
            />
            <work-item-weight
              v-if="workItemWeight"
              class="work-item-attributes-item"
              :can-update="canUpdate"
              :full-path="fullPath"
              :widget="workItemWeight"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-type="selectedWorkItemTypeName"
              @error="$emit('error', $event)"
            />
            <work-item-rolledup-dates
              v-if="workItemStartAndDueDate"
              class="work-item-attributes-item"
              :can-update="canUpdate"
              :full-path="fullPath"
              :start-date="workItemStartAndDueDate.startDate"
              :due-date="workItemStartAndDueDate.dueDate"
              :is-fixed="workItemStartAndDueDate.isFixed"
              :should-roll-up="workItemStartAndDueDate.rollUp"
              :work-item-type="selectedWorkItemTypeName"
              :work-item="workItem"
              @error="$emit('error', $event)"
            />
            <work-item-health-status
              v-if="workItemHealthStatus"
              class="work-item-attributes-item"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-type="selectedWorkItemTypeName"
              :full-path="fullPath"
              @error="$emit('error', $event)"
            />
            <work-item-color
              v-if="workItemColor"
              class="work-item-attributes-item"
              :work-item="workItem"
              :full-path="fullPath"
              :can-update="canUpdate"
              @error="$emit('error', $event)"
            />
            <work-item-parent
              v-if="workItemHierarchy"
              class="work-item-attributes-item"
              :can-update="canUpdate"
              :work-item-id="workItemId"
              :work-item-type="selectedWorkItemTypeName"
              :group-path="groupPath"
              :full-path="fullPath"
              :parent="workItemParent"
              :is-group="isGroup"
              @error="$emit('error', $event)"
            />
            <work-item-crm-contacts
              v-if="workItemCrmContacts"
              class="work-item-attributes-item"
              :full-path="fullPath"
              :work-item-id="workItemId"
              :work-item-iid="workItemIid"
              :work-item-type="selectedWorkItemTypeName"
              @error="$emit('error', $event)"
            />
          </aside>
          <div
            v-if="!stickyFormSubmit"
            class="gl-col-start-1 gl-flex gl-gap-3 gl-py-3"
            data-testid="form-buttons"
          >
            <gl-button
              variant="confirm"
              :loading="loading"
              data-testid="create-button"
              @click="createWorkItem"
            >
              {{ createWorkItemText }}
            </gl-button>
            <gl-button type="button" data-testid="cancel-button" @click="handleCancelClick">
              {{ __('Cancel') }}
            </gl-button>
          </div>
        </div>
        <!-- stick to bottom and put the Confim button on the right -->
        <!-- bg-overlap to match modal bg -->
        <div
          v-if="stickyFormSubmit"
          class="gl-border-t gl-sticky gl-bottom-0 gl-z-1 -gl-mx-5 gl-flex gl-justify-end gl-gap-3 gl-bg-overlap gl-px-5 gl-py-3"
          data-testid="form-buttons"
        >
          <gl-button type="button" data-testid="cancel-button" @click="handleCancelClick">
            {{ __('Cancel') }}
          </gl-button>
          <gl-button
            variant="confirm"
            :loading="loading"
            data-testid="create-button"
            @click="createWorkItem"
          >
            {{ createWorkItemText }}
          </gl-button>
        </div>
      </div>
    </template>
  </form>
</template>
