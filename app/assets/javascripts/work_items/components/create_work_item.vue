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
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

import { createAlert } from '~/alert';
import { clearDraft } from '~/lib/utils/autosave';
import { isMetaEnterKeyPair, parseBoolean } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { s__, sprintf, __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { addHierarchyChild, setNewWorkItemCache } from '~/work_items/graphql/cache_utils';
import { findWidget } from '~/issues/list/utils';
import TitleSuggestions from '~/issues/new/components/title_suggestions.vue';
import { addShortcutsExtension } from '~/behaviors/shortcuts';
import ZenMode from '~/zen_mode';
import ShortcutsWorkItems from '~/behaviors/shortcuts/shortcuts_work_items';
import WorkItemDates from 'ee_else_ce/work_items/components/work_item_dates.vue';
import WorkItemMetadataProvider from '~/work_items/components/work_item_metadata_provider.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import {
  getDisplayReference,
  getNewWorkItemAutoSaveKey,
  getNewWorkItemWidgetsAutoSaveKey,
  updateDraftWorkItemType,
  newWorkItemFullPath,
} from '~/work_items/utils';
import { TYPENAME_MERGE_REQUEST, TYPENAME_VULNERABILITY } from '~/graphql_shared/constants';
import {
  I18N_WORK_ITEM_ERROR_CREATING,
  i18n,
  NAME_TO_TEXT_LOWERCASE_MAP,
  NAME_TO_TEXT_MAP,
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
  WORK_ITEM_TYPE_NAME_INCIDENT,
  WORK_ITEM_TYPE_NAME_EPIC,
  WIDGET_TYPE_CUSTOM_FIELDS,
  CUSTOM_FIELDS_TYPE_NUMBER,
  CUSTOM_FIELDS_TYPE_TEXT,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WIDGET_TYPE_STATUS,
} from '../constants';
import { TITLE_LENGTH_MAX } from '../../issues/constants';
import createWorkItemMutation from '../graphql/create_work_item.mutation.graphql';
import namespaceWorkItemTypesQuery from '../graphql/namespace_work_item_types.query.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import updateNewWorkItemMutation from '../graphql/update_new_work_item.mutation.graphql';
import WorkItemProjectsListbox from './work_item_links/work_item_projects_listbox.vue';
import WorkItemNamespaceListbox from './shared/work_item_namespace_listbox.vue';
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
    WorkItemNamespaceListbox,
    TitleSuggestions,
    WorkItemParent,
    WorkItemDates,
    WorkItemWeight: () => import('ee_component/work_items/components/work_item_weight.vue'),
    WorkItemHealthStatus: () =>
      import('ee_component/work_items/components/work_item_health_status.vue'),
    WorkItemColor: () => import('ee_component/work_items/components/work_item_color.vue'),
    WorkItemIteration: () => import('ee_component/work_items/components/work_item_iteration.vue'),
    WorkItemCustomFields: () =>
      import('ee_component/work_items/components/work_item_custom_fields.vue'),
    WorkItemStatus: () => import('ee_component/work_items/components/work_item_status.vue'),
    PageHeading,
    WorkItemMetadataProvider,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    contributionGuidePath: {
      default: '',
    },
    groupPath: {
      default: '',
    },
    projectNamespaceFullPath: {
      default: '',
    },
    workItemPlanningViewEnabled: {
      default: false,
    },
  },
  i18n: {
    contributionGuidelinesText: s__(
      'WorkItem|Please review the %{linkStart}contribution guidelines%{linkEnd} for this project.',
    ),
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
    preselectedWorkItemType: {
      type: String,
      required: false,
      default: null,
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
    isModal: {
      type: Boolean,
      required: false,
      default: false,
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
    fromGlobalMenu: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isTitleValid: true,
      isConfidential:
        Boolean(getParameterByName('vulnerability_id')) ||
        parseBoolean(getParameterByName('issue[confidential]')),
      isRelatedToItem: true,
      localTitle: this.title || '',
      error: null,
      workItem: {},
      namespace: null,
      selectedProjectFullPath: this.initialSelectedProject(),
      selectedWorkItemTypeId: null,
      loading: false,
      initialLoadingWorkItem: true,
      initialLoadingWorkItemTypes: true,
      selectedNamespacePath: null,
      showWorkItemTypeSelect: false,
      discussionToResolve: getParameterByName('discussion_to_resolve'),
      mergeRequestToResolveDiscussionsOf: getParameterByName('merge_request_id'),
      vulnerabilityId: getParameterByName('vulnerability_id'),
      numberOfDiscussionsResolved: '',
      selectedParentMilestone: null,
    };
  },
  apollo: {
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
        return data?.workspace?.workItem ?? {};
      },
      result() {
        this.initialLoadingWorkItem = false;
      },
      error() {
        this.error = i18n.fetchError;
      },
    },
    namespace: {
      query() {
        return namespaceWorkItemTypesQuery;
      },
      variables() {
        return {
          fullPath: this.selectedProjectFullPath,
        };
      },
      update(data) {
        return data.workspace;
      },
      async result() {
        this.initialLoadingWorkItemTypes = false;
        if (!this.workItemTypes?.length) {
          return;
        }

        // The follow up title and description can come from the backend for the following three use cases
        // 1. when resolving a discussion in the MR and we have the merge request id in the query param
        // 2. when the issue and title are added in the query param . read https://docs.gitlab.com/user/project/issues/create_issues/#using-a-url-with-prefilled-values
        // 3. when following up a work item with a vulnerability, where we have the vulnerability id in the query param
        const workItemTitle = document.querySelector('.params-title')?.textContent.trim();
        const workItemDescription = document
          .querySelector('.params-description')
          ?.textContent.trim();

        for await (const workItemType of this.workItemTypes) {
          await setNewWorkItemCache({
            fullPath: this.selectedProjectFullPath,
            context: this.creationContext,
            widgetDefinitions: workItemType?.widgetDefinitions,
            workItemType: workItemType.name,
            workItemTypeId: workItemType.id,
            workItemTypeIconName: workItemType.iconName,
            relatedItemId: this.relatedItemId,
            workItemTitle,
            workItemDescription,
            confidential: this.isConfidential,
          });
        }

        const selectedWorkItemType = this.findWorkItemType(this.preselectedWorkItemType);

        if (selectedWorkItemType) {
          updateDraftWorkItemType({
            fullPath: this.selectedProjectFullPath,
            context: this.creationContext,
            relatedItemId: this.relatedItemId,
            workItemType: {
              id: selectedWorkItemType.id,
              name: selectedWorkItemType.name,
              iconName: selectedWorkItemType.iconName,
            },
          });
        }

        if (selectedWorkItemType) {
          this.selectedWorkItemTypeId = selectedWorkItemType?.id;
        } else {
          this.showWorkItemTypeSelect = true;
          const defaultSelectedWorkItemType =
            this.findWorkItemType(WORK_ITEM_TYPE_NAME_ISSUE) || this.workItemTypes?.at(0);
          this.selectedWorkItemTypeId = defaultSelectedWorkItemType?.id;
          this.$emit('changeType', defaultSelectedWorkItemType?.name);
        }
      },
      error() {
        this.error = s__(
          'WorkItem|Something went wrong when fetching work item types. Please try again',
        );
      },
    },
  },
  computed: {
    workItemTypes() {
      return this.namespace?.workItemTypes?.nodes ?? [];
    },
    newWorkItemPath() {
      return newWorkItemFullPath(this.selectedProjectFullPath, this.selectedWorkItemTypeName);
    },
    canSetNewWorkItemMetadata() {
      return this.namespace?.userPermissions.setNewWorkItemMetadata;
    },
    noMetadataSetPermissionMessage() {
      return sprintf(s__('WorkItem|Only %{namespaceType} members can add metadata.'), {
        namespaceType: this.isGroup ? __('group') : __('project'),
      });
    },
    isLoading() {
      return (
        this.initialLoadingWorkItemTypes || (this.initialLoadingWorkItem && !this.skipWorkItemQuery)
      );
    },
    isWorkItemTypesLoading() {
      return this.$apollo.queries.namespace.loading;
    },
    skipWorkItemQuery() {
      return !this.selectedProjectFullPath || !this.selectedWorkItemTypeName;
    },
    hasWidgets() {
      return this.workItem?.widgets?.length > 0;
    },
    relatedItemId() {
      return this.relatedItem?.id;
    },
    relatedItemReference() {
      return getDisplayReference(this.selectedProjectFullPath, this.relatedItem.reference);
    },
    relatedItemType() {
      return NAME_TO_TEXT_LOWERCASE_MAP[this.relatedItem?.type];
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
    showParentAttribute() {
      // We use the work item create work flow for incidents although
      // incidents haven't been migrated to work items and use the legacy
      // detail view instead. Since the legacy view doesn't support setting a parent
      // we need to hide this attribute here until the migration has been finished.
      // https://gitlab.com/gitlab-org/gitlab/-/issues/502823
      if (this.selectedWorkItemTypeName === WORK_ITEM_TYPE_NAME_INCIDENT) {
        return false;
      }

      // Hide Parent widget on Epic or Issue creation according to license permissions
      if (
        this.selectedWorkItemTypeName === WORK_ITEM_TYPE_NAME_ISSUE ||
        this.selectedWorkItemTypeName === WORK_ITEM_TYPE_NAME_EPIC
      ) {
        if (!this.validateAllowedParentTypes(this.selectedWorkItemTypeName).length) return false;
      }

      return Boolean(this.workItemHierarchy);
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
        text: NAME_TO_TEXT_MAP[workItemType.name],
      }));
    },
    selectedWorkItemType() {
      return this.workItemTypes?.find((item) => item.id === this.selectedWorkItemTypeId);
    },
    allowedParentTypesForSelectedType() {
      if (this.workItemTypes.length) {
        const widgetDefinitionsForCurrentType =
          this.workItemTypes.find((workItemType) => workItemType.id === this.selectedWorkItemTypeId)
            ?.widgetDefinitions || [];

        return (
          widgetDefinitionsForCurrentType.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)
            ?.allowedParentTypes?.nodes || []
        );
      }
      return [];
    },
    selectedWorkItemTypeName() {
      return this.selectedWorkItemType?.name || '';
    },
    selectedWorkItemTypeIconName() {
      return this.selectedWorkItemType?.iconName;
    },
    formOptions() {
      const options = [...this.workItemTypesForSelect];
      if (!this.preselectedWorkItemType) {
        options.unshift({ value: null, text: s__('WorkItem|Select type') });
      }
      return options;
    },
    createErrorText() {
      return sprintf(I18N_WORK_ITEM_ERROR_CREATING, {
        workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.selectedWorkItemTypeName],
      });
    },
    createWorkItemText() {
      return sprintf(s__('WorkItem|Create %{workItemType}'), {
        workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.selectedWorkItemTypeName],
      });
    },
    makeConfidentialText() {
      return sprintf(
        s__(
          'WorkItem|Turn on confidentiality: Limit visibility to %{namespace} members with at least the Planner role.',
        ),
        { namespace: this.isGroup ? __('group') : __('project') },
      );
    },
    titleText() {
      return sprintf(s__('WorkItem|New %{workItemType}'), {
        workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.selectedWorkItemTypeName],
      });
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
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
      return this.workItemMilestone?.milestone?.id || this.selectedParentMilestone?.id || null;
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
    workItemTitle() {
      return this.localTitle || this.workItem?.title || this.title;
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
    workItemStatus() {
      return findWidget(WIDGET_TYPE_STATUS, this.workItem);
    },
    workItemIid() {
      return this.workItem?.iid;
    },
    workItemStatusId() {
      return this.workItemStatus?.status?.id;
    },
    shouldIncludeRelatedItem() {
      return (
        this.isWidgetSupported(WIDGET_TYPE_LINKED_ITEMS) &&
        this.isRelatedToItem &&
        this.relatedItemId
      );
    },
    resolvingMRDiscussionLink() {
      return document.querySelector('.params-discussion-to-resolve a')?.href || '';
    },
    resolvingMRDiscussionLinkText() {
      return document.querySelector('.params-discussion-to-resolve a')?.text || '';
    },
    createWorkItemWarning() {
      const warning =
        this.numberOfDiscussionsResolved === '1'
          ? this.$options.i18n.resolveOneThreadText
          : this.$options.i18n.resolveAllThreadsText;
      return sprintf(warning, {
        workItemType: NAME_TO_TEXT_LOWERCASE_MAP[this.selectedWorkItemTypeName],
      });
    },
    isFormFilled() {
      const isTitleFilled = Boolean(this.workItemTitle.trim());
      const isDescriptionFilled = Boolean(this.workItemDescription.trim());
      const defaultColorValue = DEFAULT_EPIC_COLORS;
      const isCustomFieldsFilled = Boolean(
        this.workItemCustomFields?.find(
          (field) => field.value != null || field.selectedOptions?.length > 0,
        ),
      );

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
        Boolean(this.workItemIterationId) ||
        Boolean(this.workItemStatusId) ||
        isCustomFieldsFilled
      );
    },
    shouldDatesRollup() {
      return this.selectedWorkItemTypeName === WORK_ITEM_TYPE_NAME_EPIC;
    },
    workItemCustomFields() {
      return findWidget(WIDGET_TYPE_CUSTOM_FIELDS, this.workItem)?.customFieldValues ?? null;
    },
    inputNamespacePath() {
      if (this.shouldShowNamespaceSelector) {
        return this.selectedNamespacePath;
      }
      return this.selectedProjectFullPath;
    },
    showItemTypeSelect() {
      if (this.shouldShowNamespaceSelector) {
        return true;
      }
      return this.showWorkItemTypeSelect || this.alwaysShowWorkItemTypeSelect;
    },
    formButtonsClasses() {
      return this.isModal
        ? '-gl-mx-5 gl-px-5 gl-bg-overlap gl-py-3'
        : '-gl-mx-3 -gl-mb-10 gl-px-3 gl-bg-default gl-py-4';
    },
    selectedProjectGroupPath() {
      // Eventually, we should be able to select both groups and projects from a single interface in consolidated list.
      if (this.selectedProjectFullPath && this.selectedProjectFullPath.indexOf('/') === -1) {
        return this.selectedProjectFullPath;
      }
      return this.selectedProjectFullPath
        ? this.selectedProjectFullPath.substring(0, this.selectedProjectFullPath.lastIndexOf('/'))
        : this.groupPath;
    },
    shouldShowNamespaceSelector() {
      if (this.workItemPlanningViewEnabled) {
        return this.fromGlobalMenu || (this.isGroup && !this.isEpicsList);
      }
      return false;
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
    addShortcutsExtension(ShortcutsWorkItems);
    new ZenMode(); // eslint-disable-line no-new

    // Set focus on title field
    this.$nextTick(async () => {
      await new Promise((resolve) => {
        setTimeout(resolve, 250);
      });

      this.$refs.title?.focusInput?.();
    });
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleKeydown);
  },
  methods: {
    findWorkItemType(workItemTypeName) {
      return this.workItemTypes?.find((workItemType) => workItemType.name === workItemTypeName);
    },
    initialSelectedProject() {
      if (this.relatedItem) {
        return this.relatedItem.reference.substring(0, this.relatedItem.reference.lastIndexOf('#'));
      }
      return this.fullPath || null;
    },
    handleKeydown(e) {
      if (isMetaEnterKeyPair(e) && !this.loading) {
        this.createWorkItem();
      }
    },
    validateAllowedParentTypes(selectedWorkItemType) {
      return (
        this.workItemTypes
          ?.find((type) => type.name === selectedWorkItemType)
          ?.widgetDefinitions.find((widget) => widget.type === WIDGET_TYPE_HIERARCHY)
          .allowedParentTypes?.nodes || []
      );
    },
    isWidgetSupported(widgetType) {
      const widgetDefinitions =
        this.selectedWorkItemType?.widgetDefinitions?.flatMap((i) => i.type) || [];
      return widgetDefinitions.indexOf(widgetType) !== -1;
    },
    validate() {
      this.isTitleValid =
        Boolean(String(this.workItemTitle).trim()) &&
        String(this.workItemTitle).trim().length <= TITLE_LENGTH_MAX;
    },
    setNumberOfDiscussionsResolved() {
      if (this.discussionToResolve || this.mergeRequestToResolveDiscussionsOf) {
        this.numberOfDiscussionsResolved =
          this.discussionToResolve && this.mergeRequestToResolveDiscussionsOf ? '1' : 'all';
      }
    },
    clearAutosaveDraft() {
      const fullDraftAutosaveKey = getNewWorkItemAutoSaveKey({
        fullPath: this.selectedProjectFullPath,
        context: this.creationContext,
        workItemType: this.selectedWorkItemTypeName,
        relatedItemId: this.relatedItemId,
      });
      clearDraft(fullDraftAutosaveKey);

      const widgetsAutosaveKey = getNewWorkItemWidgetsAutoSaveKey({
        fullPath: this.selectedProjectFullPath,
        context: this.creationContext,
        relatedItemId: this.relatedItemId,
      });
      clearDraft(widgetsAutosaveKey);
    },
    handleChangeType() {
      setNewWorkItemCache({
        fullPath: this.selectedProjectFullPath,
        context: this.creationContext,
        widgetDefinitions: this.selectedWorkItemType?.widgetDefinitions || [],
        workItemType: this.selectedWorkItemTypeName,
        workItemTypeId: this.selectedWorkItemTypeId,
        workItemTypeIconName: this.selectedWorkItemTypeIconName,
        relatedItemId: this.relatedItemId,
      });

      updateDraftWorkItemType({
        fullPath: this.selectedProjectFullPath,
        context: this.creationContext,
        relatedItemId: this.relatedItemId,
        workItemType: {
          id: this.selectedWorkItemTypeId,
          name: this.selectedWorkItemTypeName,
          iconName: this.selectedWorkItemTypeIconName,
        },
      });

      this.$emit('changeType', this.selectedWorkItemTypeName);
    },
    async updateDraftData(type, value) {
      if (type === 'title') {
        this.localTitle = value;
        this.validate();
      }

      await this.handleUpdateWidgetDraft({ [type]: value });
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
        namespacePath: this.inputNamespacePath || this.fullPath,
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

      if (this.vulnerabilityId) {
        workItemCreateInput.vulnerabilityId = convertToGraphQLId(
          TYPENAME_VULNERABILITY,
          this.vulnerabilityId,
        );
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

      if (this.isWidgetSupported(WIDGET_TYPE_STATUS)) {
        workItemCreateInput.statusWidget = {
          status: this.workItemStatusId,
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

      if (this.isWidgetSupported(WIDGET_TYPE_CUSTOM_FIELDS)) {
        const customFieldsMutationInput = this.workItemCustomFields?.map((field) => {
          if (field.customField.fieldType === CUSTOM_FIELDS_TYPE_NUMBER) {
            return {
              customFieldId: field.customField.id,
              numberValue: field.value,
            };
          }

          if (field.customField.fieldType === CUSTOM_FIELDS_TYPE_TEXT) {
            return {
              customFieldId: field.customField.id,
              textValue: field.value,
            };
          }

          const selectedOptionsIds = field.selectedOptions?.map(({ id }) => id);
          return {
            customFieldId: field.customField.id,
            selectedOptionIds: selectedOptionsIds,
          };
        });

        workItemCreateInput.customFieldsWidget = customFieldsMutationInput;
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

        this.clearAutosaveDraft();
      } catch {
        this.error = this.createErrorText;
        this.loading = false;
      }
    },
    async handleUpdateWidgetDraft(input) {
      try {
        await this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              fullPath: this.selectedProjectFullPath,
              context: this.creationContext,
              workItemType: this.selectedWorkItemTypeName,
              relatedItemId: this.relatedItemId,
              ...input,
            },
          },
        });
      } catch (e) {
        this.error = this.createErrorText;
        Sentry.captureException(e);
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
      this.clearAutosaveDraft();

      const selectedWorkItemWidgets = this.selectedWorkItemType?.widgetDefinitions || [];

      setNewWorkItemCache({
        fullPath: this.selectedProjectFullPath,
        context: this.creationContext,
        widgetDefinitions: selectedWorkItemWidgets,
        workItemType: this.selectedWorkItemTypeName,
        workItemTypeId: this.selectedWorkItemTypeId,
        workItemTypeIconName: this.selectedWorkItemTypeIconName,
        relatedItemId: this.relatedItemId,
      });
    },
    onParentMilestone(parentMilestone) {
      this.selectedParentMilestone = parentMilestone;
    },
  },
  NEW_WORK_ITEM_IID,
  NEW_WORK_ITEM_GID,
};
</script>

<template>
  <work-item-metadata-provider :full-path="fullPath">
    <form @submit.prevent="createWorkItem">
      <work-item-loading v-if="isLoading" class="gl-mt-5" />
      <template v-else>
        <gl-alert v-if="error" class="gl-mb-3" variant="danger" @dismiss="error = null">
          {{ error }}
        </gl-alert>
        <page-heading v-if="!hideFormTitle" :heading="titleText" />

        <div class="gl-flex gl-items-center gl-gap-4">
          <template v-if="shouldShowNamespaceSelector">
            <gl-form-group class="gl-mr-4 gl-max-w-26 gl-flex-grow" :label="__('Group/project')">
              <work-item-namespace-listbox
                v-model="selectedNamespacePath"
                :full-path="fullPath"
                :is-group="isGroup"
                :limit-to-current-namespace="!fromGlobalMenu"
              />
            </gl-form-group>
          </template>

          <template v-else>
            <gl-form-group
              v-if="showProjectSelector"
              class="gl-max-w-26 gl-flex-grow"
              :label="__('Project')"
              label-for="create-work-item-project"
            >
              <work-item-projects-listbox
                v-model="selectedProjectFullPath"
                :full-path="fullPath"
                :is-group="isGroup"
                :current-project-name="namespaceFullName"
                :project-namespace-full-path="projectNamespaceFullPath"
                toggle-id="create-work-item-project"
              />
            </gl-form-group>
          </template>

          <gl-form-group
            v-if="showItemTypeSelect"
            class="gl-max-w-26 gl-flex-grow"
            label-class="!gl-pb-0"
          >
            <slot name="label">
              <div class="gl-mb-3 gl-flex gl-items-center gl-gap-2">
                <label class="gl-m-0 gl-block gl-leading-normal" for="work-item-type">
                  {{ __('Type') }}
                </label>
                <gl-loading-icon v-if="isWorkItemTypesLoading" />
              </div>
            </slot>
            <gl-form-select
              id="work-item-type"
              v-model="selectedWorkItemTypeId"
              :disabled="isWorkItemTypesLoading"
              data-testid="work-item-types-select"
              :options="formOptions"
              @change="handleChangeType"
            />
          </gl-form-group>
        </div>
        <div data-testid="work-item-overview" class="work-item-overview gl-mb-3">
          <template v-if="selectedWorkItemTypeId">
            <work-item-title
              ref="title"
              data-testid="title-input"
              is-editing
              :is-valid="isTitleValid"
              :title="workItemTitle"
              @updateDraft="updateDraftData('title', $event)"
            />
            <title-suggestions
              :project-path="selectedProjectFullPath"
              :search="workItemTitle"
              :help-text="$options.i18n.similarWorkItemHelpText"
              :title="$options.i18n.suggestionTitle"
            />

            <section>
              <work-item-description
                class="create-work-item-description"
                edit-mode
                is-create-flow
                :is-group="isGroup"
                :autofocus="false"
                :description="description"
                :full-path="selectedProjectFullPath"
                :show-buttons-below-field="false"
                :hide-fullscreen-markdown-button="isModal"
                :new-work-item-type="selectedWorkItemTypeName"
                :work-item-id="workItemId"
                :work-item-iid="workItemIid"
                @error="updateError = $event"
                @cancelCreate="handleCancelClick"
                @updateDraft="updateDraftData('description', $event)"
              />
              <div
                v-if="numberOfDiscussionsResolved && resolvingMRDiscussionLink"
                class="gl-mb-4"
                data-testid="work-item-resolve-discussion"
              >
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
                    s__(
                      'WorkItem|Mark this item as related to: %{workItemType} %{workItemReference}',
                    )
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
              <template v-if="canSetNewWorkItemMetadata">
                <work-item-status
                  v-if="workItemStatus"
                  class="work-item-attributes-item"
                  :can-update="canUpdate"
                  :full-path="selectedProjectFullPath"
                  :is-group="isGroup"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :work-item-type="selectedWorkItemTypeName"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-assignees
                  v-if="workItemAssignees"
                  class="js-assignee work-item-attributes-item"
                  :can-update="canUpdate"
                  :full-path="selectedProjectFullPath"
                  :is-group="isGroup"
                  :work-item-id="workItemId"
                  :assignees="workItemAssignees.assignees.nodes"
                  :participants="workItemParticipantNodes"
                  :allows-multiple-assignees="workItemAssignees.allowsMultipleAssignees"
                  :work-item-type="selectedWorkItemTypeName"
                  :can-invite-members="workItemAssignees.canInviteMembers"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-labels
                  v-if="workItemLabels"
                  class="js-labels work-item-attributes-item"
                  :can-update="canUpdate"
                  :full-path="selectedProjectFullPath"
                  :is-group="isGroup"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :work-item-type="selectedWorkItemTypeName"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-parent
                  v-if="showParentAttribute"
                  class="work-item-attributes-item"
                  :can-update="canUpdate"
                  :work-item-id="workItemId"
                  :work-item-type="selectedWorkItemTypeName"
                  :group-path="selectedProjectGroupPath"
                  :full-path="selectedProjectFullPath"
                  :parent="workItemParent"
                  :is-group="isGroup"
                  :allowed-parent-types-for-new-work-item="allowedParentTypesForSelectedType"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                  @parentMilestone="onParentMilestone"
                />
                <work-item-weight
                  v-if="workItemWeight"
                  class="work-item-attributes-item"
                  :can-update="canUpdate"
                  :widget="workItemWeight"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :work-item-type="selectedWorkItemTypeName"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-milestone
                  v-if="workItemMilestone"
                  class="js-milestone work-item-attributes-item"
                  :is-group="isGroup"
                  :full-path="selectedProjectFullPath"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :work-item-milestone="workItemMilestone.milestone || selectedParentMilestone"
                  :work-item-type="selectedWorkItemTypeName"
                  :can-update="canUpdate"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                  @parentMilestone="onParentMilestone"
                />
                <work-item-iteration
                  v-if="workItemIteration"
                  class="work-item-attributes-item"
                  :full-path="selectedProjectFullPath"
                  :is-group="isGroup"
                  :iteration="workItemIteration.iteration"
                  :can-update="canUpdate"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :work-item-type="selectedWorkItemTypeName"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-dates
                  v-if="workItemStartAndDueDate"
                  class="work-item-attributes-item"
                  :can-update="canUpdate"
                  :start-date="workItemStartAndDueDate.startDate"
                  :due-date="workItemStartAndDueDate.dueDate"
                  :is-fixed="workItemStartAndDueDate.isFixed"
                  :should-roll-up="shouldDatesRollup"
                  :work-item-type="selectedWorkItemTypeName"
                  :work-item="workItem"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-health-status
                  v-if="workItemHealthStatus"
                  class="work-item-attributes-item"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :work-item-type="selectedWorkItemTypeName"
                  :full-path="selectedProjectFullPath"
                  :is-work-item-closed="false"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-color
                  v-if="workItemColor"
                  class="work-item-attributes-item"
                  :work-item="workItem"
                  :can-update="canUpdate"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-custom-fields
                  v-if="workItemCustomFields"
                  :work-item-id="workItemId"
                  :work-item-type="selectedWorkItemTypeName"
                  :custom-fields="workItemCustomFields"
                  :can-update="canUpdate"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
                <work-item-crm-contacts
                  v-if="workItemCrmContacts"
                  class="work-item-attributes-item"
                  :full-path="selectedProjectFullPath"
                  :work-item-id="workItemId"
                  :work-item-iid="workItemIid"
                  :work-item-type="selectedWorkItemTypeName"
                  @updateWidgetDraft="handleUpdateWidgetDraft"
                  @error="$emit('error', $event)"
                />
              </template>
              <template v-else>
                <strong>
                  <gl-icon name="information-o" />
                  {{ s__('WorkItem|Limited access') }}
                </strong>
                <div>{{ noMetadataSetPermissionMessage }}</div>
              </template>
            </aside>
          </template>
        </div>
        <div
          class="gl-border-t gl-sticky gl-bottom-0 gl-z-1 gl-flex gl-flex-col gl-justify-between gl-gap-2 @sm:gl-flex-row @sm:gl-items-center"
          :class="formButtonsClasses"
          data-testid="form-buttons"
        >
          <!-- We're duplicating information here in a differnet order, rather than reordering with CSS, to maintain correct tab ordering for accessibility -->
          <!-- In modal, contribution guidelines come first; in standalone page, buttons come first -->
          <div v-if="isModal">
            <div v-if="contributionGuidePath" class="gl-text-sm">
              <gl-sprintf :message="$options.i18n.contributionGuidelinesText">
                <template #link="{ content }">
                  <gl-link class="gl-font-bold" :href="contributionGuidePath">
                    {{ content }}
                  </gl-link>
                </template>
              </gl-sprintf>
            </div>
          </div>

          <!-- In modal, "Cancel" is first; in standalone page, "Create" is first -->
          <div class="gl-flex gl-justify-end gl-gap-3">
            <gl-button
              v-if="isModal"
              type="button"
              data-testid="cancel-button"
              @click="handleCancelClick"
            >
              {{ __('Cancel') }}
            </gl-button>
            <gl-button
              variant="confirm"
              :disabled="!isTitleValid"
              :loading="loading"
              data-testid="create-button"
              @click="createWorkItem"
            >
              {{ createWorkItemText }}
            </gl-button>
            <gl-button
              v-if="!isModal"
              type="button"
              data-testid="cancel-button"
              @click="handleCancelClick"
            >
              {{ __('Cancel') }}
            </gl-button>
          </div>

          <div v-if="contributionGuidePath && !isModal" class="gl-text-sm">
            <gl-sprintf :message="$options.i18n.contributionGuidelinesText">
              <template #link="{ content }">
                <gl-link class="gl-font-bold" :href="contributionGuidePath">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </div>
        </div>
      </template>
    </form>
  </work-item-metadata-provider>
</template>
