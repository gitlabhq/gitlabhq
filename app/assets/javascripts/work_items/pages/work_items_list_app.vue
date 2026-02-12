<script>
import {
  GlButton,
  GlFilteredSearchToken,
  GlLoadingIcon,
  GlIcon,
  GlTooltipDirective,
  GlSkeletonLoader,
  GlModalDirective,
  GlAlert,
} from '@gitlab/ui';
import produce from 'immer';
import { isEmpty, isEqual } from 'lodash';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { createAlert, VARIANT_INFO } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import IssueCardStatistics from 'ee_else_ce/work_items/list/components/issue_card_statistics.vue';
import IssueCardTimeInfo from 'ee_else_ce/work_items/list/components/issue_card_time_info.vue';
import {
  convertToApiParams,
  convertToSearchQuery,
  convertToUrlParams,
  deriveSortKey,
  getDefaultWorkItemTypes,
  getFilterTokens,
  getSavedViewFilterTokens,
  getInitialPageParams,
  getSortOptions,
  groupMultiSelectFilterTokens,
  saveSavedView,
} from 'ee_else_ce/work_items/list/utils';
import axios from '~/lib/utils/axios_utils';
import { TYPENAME_NAMESPACE, TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  STATUS_ALL,
  STATUS_CLOSED,
  STATUS_OPEN,
  NAMESPACE_GROUP,
  NAMESPACE_PROJECT,
} from '~/issues/constants';
import { AutocompleteCache } from '~/issues/dashboard/utils';
import EmptyStateWithAnyTickets from '~/issues/service_desk/components/empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyTickets from '~/issues/service_desk/components/empty_state_without_any_issues.vue';
import InfoBanner from '~/issues/service_desk/components/info_banner.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import {
  CREATED_DESC,
  ISSUE_REFERENCE,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_SORT,
  PARAM_STATE,
  urlSortParams,
  UPDATED_DESC,
  RELATIVE_POSITION_ASC,
} from '~/work_items/list/constants';
import searchLabelsQuery from '~/work_items/list/graphql/search_labels.query.graphql';
import namespaceWorkItemTypesQuery from '~/work_items/graphql/namespace_work_item_types.query.graphql';
import getSubscribedSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import namespaceSavedViewQuery from '~/work_items/graphql/namespace_saved_view.query.graphql';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { scrollUp } from '~/lib/utils/scroll_utils';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import { setPageFullWidth, setPageDefaultWidth, isLoggedIn } from '~/lib/utils/common_utils';
import { __, s__, n__, formatNumber, sprintf } from '~/locale';
import {
  OPERATOR_IS,
  OPERATORS_AFTER_BEFORE,
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  OPERATORS_IS_NOT_OR,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TITLE_CLOSED,
  TOKEN_TITLE_CONFIDENTIAL,
  TOKEN_TITLE_CREATED,
  TOKEN_TITLE_DUE_DATE,
  TOKEN_TITLE_GROUP,
  TOKEN_TITLE_LABEL,
  TOKEN_TITLE_MILESTONE,
  TOKEN_TITLE_MY_REACTION,
  TOKEN_TITLE_SEARCH_WITHIN,
  TOKEN_TITLE_STATE,
  TOKEN_TITLE_SUBSCRIBED,
  TOKEN_TITLE_TYPE,
  TOKEN_TITLE_UPDATED,
  TOKEN_TITLE_ORGANIZATION,
  TOKEN_TITLE_CONTACT,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
  TOKEN_TYPE_CLOSED,
  TOKEN_TYPE_CONFIDENTIAL,
  TOKEN_TYPE_CREATED,
  TOKEN_TYPE_DUE_DATE,
  TOKEN_TYPE_GROUP,
  TOKEN_TYPE_LABEL,
  TOKEN_TYPE_MILESTONE,
  TOKEN_TYPE_MY_REACTION,
  TOKEN_TYPE_SEARCH_WITHIN,
  TOKEN_TYPE_STATE,
  TOKEN_TYPE_SUBSCRIBED,
  TOKEN_TYPE_TYPE,
  TOKEN_TYPE_UPDATED,
  TOKEN_TYPE_ORGANIZATION,
  TOKEN_TYPE_CONTACT,
  TOKEN_TYPE_RELEASE,
  TOKEN_TITLE_RELEASE,
  TOKEN_TYPE_PARENT,
  TOKEN_TITLE_PARENT,
} from '~/vue_shared/components/filtered_search_bar/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getWorkItemStateCountsQuery from 'ee_else_ce/work_items/list/graphql/get_work_item_state_counts.query.graphql';
import getWorkItemsQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_full.query.graphql';
import getWorkItemsSlimQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_slim.query.graphql';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import hasWorkItemsQuery from '~/work_items/list/graphql/has_work_items.query.graphql';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { initWorkItemsFeedback } from '~/work_items_feedback';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import CreateWorkItemModal from '../components/create_work_item_modal.vue';
import WorkItemDrawer from '../components/work_item_drawer.vue';
import HealthStatus from '../list/components/health_status.vue';
import WorkItemListHeading from '../list/components/work_item_list_heading.vue';
import WorkItemUserPreferences from '../list/components/work_item_user_preferences.vue';
import WorkItemListActions from '../list/components/work_item_list_actions.vue';
import WorkItemsNewSavedViewModal from '../list/components/work_items_new_saved_view_modal.vue';
import WorkItemsOnboardingModal from '../components/work_items_onboarding_modal/work_items_onboarding_modal.vue';
import WorkItemsSavedViewsSelectors from '../list/components/work_items_saved_views_selectors.vue';
import {
  CREATION_CONTEXT_LIST_ROUTE,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  NAME_TO_ENUM_MAP,
  STATE_CLOSED,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  WORK_ITEM_TYPE_NAME_TICKET,
  METADATA_KEYS,
  WORK_ITEM_CREATE_SOURCES,
  ROUTES,
} from '../constants';
import workItemsReorderMutation from '../graphql/work_items_reorder.mutation.graphql';
import EmptyStateWithAnyIssues from '../list/components/empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from '../list/components/empty_state_without_any_issues.vue';
import searchProjectsQuery from '../list/graphql/search_projects.query.graphql';
import { combineWorkItemLists, findHierarchyWidget } from '../utils';
import getUserWorkItemsPreferences from '../graphql/get_user_preferences.query.graphql';

const DateToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/date_token.vue');
const EmojiToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/emoji_token.vue');
const GroupToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/group_token.vue');
const LabelToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/label_token.vue');
const MilestoneToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/milestone_token.vue');
const UserToken = () => import('~/vue_shared/components/filtered_search_bar/tokens/user_token.vue');
const ReleaseToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/release_token.vue');
const LocalBoard = () => import('./local_board/local_board.vue');
const CrmOrganizationToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/crm_organization_token.vue');
const CrmContactToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/crm_contact_token.vue');
const WorkItemParentToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/work_item_parent_token.vue');
const WorkItemTypeToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/work_item_type_token.vue');

const CONSOLIDATED_LIST_FEEDBACK_PROMPT_EXPIRY = '2026-01-01';
const FEATURE_NAME = 'work_item_consolidated_list_feedback';

export default {
  CREATION_CONTEXT_LIST_ROUTE,
  issuableListTabs,
  searchProjectsQuery,
  WORK_ITEM_CREATE_SOURCES,
  importModalId: 'work-item-import-modal',
  components: {
    GlLoadingIcon,
    GlButton,
    InfoBanner,
    IssuableList,
    IssueCardStatistics,
    IssueCardTimeInfo,
    WorkItemBulkEditSidebar: () =>
      import('~/work_items/list/components/work_item_bulk_edit_sidebar.vue'),
    WorkItemDrawer,
    HealthStatus,
    EmptyStateWithAnyIssues,
    EmptyStateWithoutAnyIssues,
    EmptyStateWithAnyTickets,
    EmptyStateWithoutAnyTickets,
    CreateWorkItemModal,
    LocalBoard,
    WorkItemListHeading,
    WorkItemUserPreferences,
    WorkItemListActions,
    GlIcon,
    GlSkeletonLoader,
    NewResourceDropdown,
    WorkItemsSavedViewsSelectors,
    GlAlert,
    WorkItemsNewSavedViewModal,
    WorkItemsOnboardingModal,
    UserCalloutDismisser,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagMixin()],
  inject: [
    'autocompleteAwardEmojisPath',
    'canAdminIssue',
    'canBulkAdminEpic',
    'canCreateProjects',
    'canCreateWorkItem',
    'hasBlockedIssuesFeature',
    'hasEpicsFeature',
    'hasGroupBulkEditFeature',
    'hasIssuableHealthStatusFeature',
    'hasIssueDateFilterFeature',
    'hasIssueWeightsFeature',
    'hasOkrsFeature',
    'hasQualityManagementFeature',
    'hasCustomFieldsFeature',
    'isGroup',
    'isProject',
    'isServiceDeskSupported',
    'showNewWorkItem',
    'workItemType',
    'canReadCrmOrganization',
    'hasStatusFeature',
    'canReadCrmContact',
    'releasesPath',
    'metadataLoading',
    'newWorkItemEmailAddress',
    'isGroupIssuesList',
    'groupId',
    'canImportWorkItems',
    'isIssueRepositioningDisabled',
    'hasProjects',
    'newIssuePath',
    'workItemPlanningViewEnabled',
    'workItemsSavedViewsEnabled',
    'subscribedSavedViewLimit',
  ],
  props: {
    eeWorkItemUpdateCount: {
      type: Number,
      required: false,
      default: 0,
    },
    withTabs: {
      type: Boolean,
      required: false,
      default: true,
    },
    eeSearchTokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      error: undefined,
      bulkEditInProgress: false,
      subscribedSavedViews: [],
      filterTokens: [],
      initialViewTokens: [],
      isInitialLoadComplete: false,
      pageInfo: {},
      pageParams: {},
      pageSize: DEFAULT_PAGE_SIZE,
      showBulkEditSidebar: false,
      sortKey: CREATED_DESC,
      initialSortKey: CREATED_DESC,
      initialViewSortKey: null,
      initialPreferences: null,
      state: STATUS_OPEN,
      workItemsFull: [],
      workItemsSlim: [],
      workItemStateCounts: {},
      activeItem: null,
      hasStateToken: false,
      initialLoadWasFiltered: false,
      showLocalBoard: false,
      namespaceId: null,
      displaySettings: {},
      localDisplaySettings: {},
      initialViewDisplaySettings: {},
      workItemTypes: [],
      isLoggedIn: isLoggedIn(),
      isSortKeyInitialized: !this.isLoggedIn,
      hasWorkItems: false,
      workItemsCount: null,
      isNewViewModalVisible: false,
      savedView: null,
    };
  },
  apollo: {
    displaySettings: {
      context: {
        featureCategory: 'portfolio_management',
      },
      query: getUserWorkItemsPreferences,
      variables() {
        return {
          namespace: this.rootPageFullPath,
          workItemTypeId: this.workItemTypeId,
          userPreferencesOnly: this.isSavedView,
        };
      },
      update(data) {
        const commonPreferences = data?.currentUser?.userPreferences?.workItemsDisplaySettings ?? {
          shouldOpenItemsInSidePanel: true,
        };
        const namespacePreferences = data?.currentUser?.workItemPreferences?.displaySettings ?? {};
        return {
          commonPreferences,
          namespacePreferences,
        };
      },
      result({ data }) {
        const { sort } = data?.currentUser?.workItemPreferencesWithType ?? {};
        let sortKey = deriveSortKey({
          sort: getParameterByName(PARAM_SORT) || sort,
        });
        if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
          this.showIssueRepositioningMessage();
          sortKey = this.state === STATUS_CLOSED ? UPDATED_DESC : CREATED_DESC;
        }
        if (!this.isSavedView) this.sortKey = sortKey;
        this.isSortKeyInitialized = true;
      },
      skip() {
        return !this.workItemTypeId || !this.isLoggedIn;
      },
      error(error) {
        this.isSortKeyInitialized = true;
        this.error = __('An error occurred while getting work item user preference.');
        Sentry.captureException(error);
      },
    },
    workItemsFull() {
      return this.createWorkItemQuery(getWorkItemsQuery);
    },
    workItemsSlim() {
      return this.createWorkItemQuery(getWorkItemsSlimQuery);
    },
    workItemsCount: {
      query() {
        return getWorkItemsCountOnlyQuery;
      },
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.namespace?.workItems.count || 0;
      },
      skip() {
        return isEmpty(this.pageParams) || this.metadataLoading || !this.isPlanningViewsEnabled;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    // TODO: remove entirely once consolidated list is GA
    workItemStateCounts: {
      query: getWorkItemStateCountsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.[this.namespace]?.workItemStateCounts ?? {};
      },
      skip() {
        return (
          (this.isPlanningViewsEnabled && !this.isServiceDeskList) ||
          isEmpty(this.pageParams) ||
          this.metadataLoading ||
          this.savedViewNotFound
        );
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    hasWorkItems: {
      query: hasWorkItemsQuery,
      variables() {
        const singleWorkItemType = this.workItemType ? NAME_TO_ENUM_MAP[this.workItemType] : null;
        return {
          fullPath: this.rootPageFullPath,
          types: singleWorkItemType || this.defaultWorkItemTypes,
        };
      },
      update(data) {
        return data?.namespace?.workItems.nodes.length > 0 || false;
      },
      error(error) {
        this.error = s__('WorkItem|An error occurred while getting work item counts.');
        Sentry.captureException(error);
      },
      result() {
        if (!this.isInitialLoadComplete) {
          this.isInitialLoadComplete = true;
          this.initialLoadWasFiltered = this.filterTokens.length > 0;
        }
      },
    },
    workItemTypes: {
      query: namespaceWorkItemTypesQuery,
      variables() {
        return {
          fullPath: this.rootPageFullPath,
        };
      },
      update(data) {
        return data?.namespace?.workItemTypes?.nodes;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    savedView: {
      query: namespaceSavedViewQuery,
      variables() {
        return {
          fullPath: this.rootPageFullPath,
          id: this.savedViewId,
        };
      },
      skip() {
        return !this.isSavedView;
      },
      update(data) {
        return data?.namespace?.savedViews?.nodes[0];
      },
      result({ data }) {
        try {
          const draft = localStorage.getItem(this.savedViewDraftStorageKey);
          const savedView = data?.namespace?.savedViews?.nodes[0];
          if (!savedView) {
            throw new Error(
              `Unable to find saved view with id ${this.savedViewId} in ${this.rootPageFullPath}`,
            );
          }
          const tokens = this.getFilterTokensFromSavedView(savedView?.filters || {});
          this.initialViewTokens = tokens;
          this.initialViewSortKey = savedView?.sort;
          this.initialViewDisplaySettings = {
            commonPreferences: { ...this.displaySettings.commonPreferences },
            namespacePreferences: savedView.displaySettings,
          };

          if (draft) {
            this.restoreViewDraft();
          } else {
            this.filterTokens = tokens;
            this.sortKey = savedView?.sort;
            this.localDisplaySettings = {
              commonPreferences: { ...this.displaySettings.commonPreferences },
              namespacePreferences: savedView.displaySettings,
            };
          }
        } catch (error) {
          Sentry.captureException(error);
        }
      },
      error(error) {
        Sentry.captureException(error);
      },
    },
    subscribedSavedViews: {
      query: getSubscribedSavedViewsQuery,
      variables() {
        return {
          fullPath: this.rootPageFullPath,
          subscribedOnly: true,
          sort: 'RELATIVE_POSITION',
        };
      },
      update(data) {
        return data?.namespace?.savedViews?.nodes ?? [];
      },
      skip() {
        return !this.workItemsSavedViewsEnabled;
      },
      error(e) {
        Sentry.captureException(e);
      },
    },
  },
  computed: {
    savedViewId() {
      return convertToGraphQLId('WorkItems::SavedViews::SavedView', this.$route.params.view_id);
    },
    savedViewNotFound() {
      return this.isSavedView && !this.savedView;
    },
    displaySettingsSoT() {
      return this.isSavedView ? this.localDisplaySettings : this.displaySettings;
    },
    isSavedView() {
      return this.$route.name === ROUTES.savedView;
    },
    isInfoBannerVisible() {
      return this.isServiceDeskList && this.isServiceDeskSupported && this.hasWorkItems;
    },
    workItems() {
      return combineWorkItemLists(
        this.workItemsSlim,
        this.workItemsFull,
        Boolean(this.glFeatures.workItemFeaturesField),
      );
    },
    shouldShowList() {
      return (
        this.hasWorkItems === true ||
        this.error ||
        this.initialLoadWasFiltered ||
        this.workItems.length > 0 ||
        !this.isEpicsList
      );
    },
    detailLoading() {
      return this.$apollo.queries.workItemsFull.loading;
    },
    isItemSelected() {
      return !isEmpty(this.activeItem);
    },
    allowBulkEditing() {
      if (this.isEpicsList) {
        return this.canBulkAdminEpic;
      }
      if (!this.isGroup) {
        return this.canAdminIssue;
      }
      // Groups require EE bulk edit feature, or CE planning view with projects
      const hasCEBulkEdit =
        this.workItemPlanningViewEnabled && this.hasProjects && !this.hasEpicsFeature;
      return this.canAdminIssue && (this.hasGroupBulkEditFeature || hasCEBulkEdit);
    },
    apiFilterParams() {
      return convertToApiParams(this.filterTokens, {
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
        hasStatusFeature: this.hasStatusFeature,
      });
    },
    defaultWorkItemTypes() {
      return getDefaultWorkItemTypes({
        hasEpicsFeature: this.hasEpicsFeature,
        hasOkrsFeature: this.hasOkrsFeature,
        hasQualityManagementFeature: this.hasQualityManagementFeature,
        isGroupIssuesList: this.isGroupIssuesList,
      });
    },
    workItemDrawerEnabled() {
      return this.displaySettings.commonPreferences?.shouldOpenItemsInSidePanel ?? true;
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
    },
    isServiceDeskList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_TICKET;
    },
    hasSearch() {
      return Boolean(this.searchQuery);
    },
    isLoading() {
      return this.$apollo.queries.workItemsSlim.loading;
    },
    isOpenTab() {
      return this.state === STATUS_OPEN;
    },
    namespace() {
      return this.isGroup ? NAMESPACE_GROUP : NAMESPACE_PROJECT;
    },
    queryVariables() {
      const hasGroupFilter = Boolean(this.urlFilterParams.group_path);
      const singleWorkItemType = this.workItemType ? NAME_TO_ENUM_MAP[this.workItemType] : null;
      const isIidSearch = ISSUE_REFERENCE.test(this.searchQuery);
      return {
        fullPath: this.rootPageFullPath,
        sort: this.sortKey,
        state: this.state,
        ...this.apiFilterParams,
        ...this.pageParams,
        iid: isIidSearch ? this.searchQuery.slice(1) : undefined,
        search: isIidSearch ? undefined : this.searchQuery,
        excludeProjects: hasGroupFilter || this.isEpicsList,
        includeDescendants: !hasGroupFilter,
        types: this.apiFilterParams.types || singleWorkItemType || this.defaultWorkItemTypes,
        isGroup: this.isGroup,
        excludeGroupWorkItems: this.isGroupIssuesList,
        useWorkItemFeatures: Boolean(this.glFeatures.workItemFeaturesField),
      };
    },
    csvExportQueryVariables() {
      const singleWorkItemType = this.workItemType ? NAME_TO_ENUM_MAP[this.workItemType] : null;
      return {
        ...this.apiFilterParams,
        projectPath: this.rootPageFullPath,
        state: this.state,
        search: this.searchQuery,
        types: this.apiFilterParams.types || singleWorkItemType || this.defaultWorkItemTypes,
      };
    },
    searchQuery() {
      return convertToSearchQuery(this.filterTokens);
    },
    searchTokens() {
      const preloadedUsers = [];

      if (gon.current_user_id) {
        preloadedUsers.push({
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          name: gon.current_user_fullname,
          username: gon.current_username,
          avatar_url: gon.current_user_avatar_url,
        });
      }

      const tokens = [
        {
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
          multiSelect: true,
        },
        {
          type: TOKEN_TYPE_AUTHOR,
          title: TOKEN_TITLE_AUTHOR,
          icon: 'pencil',
          unique: true, // need not to be unique but the BE supports only one author in "IS" condition
          token: UserToken,
          dataType: 'user',
          defaultUsers: [],
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-author`,
          preloadedUsers,
          multiSelect: true,
        },
        {
          type: TOKEN_TYPE_LABEL,
          title: TOKEN_TITLE_LABEL,
          icon: 'labels',
          token: LabelToken,
          operators: OPERATORS_IS_NOT_OR,
          fetchLabels: this.fetchLabels,
          fetchLatestLabels: this.fetchLatestLabels,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-label`,
          multiSelect: true,
        },
        {
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-milestone`,
          shouldSkipSort: true,
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
        },
        {
          type: TOKEN_TYPE_SEARCH_WITHIN,
          title: TOKEN_TITLE_SEARCH_WITHIN,
          icon: 'search',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            { icon: 'title', value: 'TITLE', title: __('Titles') },
            { icon: 'text-description', value: 'DESCRIPTION', title: __('Descriptions') },
          ],
        },
      ];

      if (this.isGroup && !this.isGroupIssuesList) {
        tokens.push({
          type: TOKEN_TYPE_GROUP,
          icon: 'group',
          title: TOKEN_TITLE_GROUP,
          unique: true,
          token: GroupToken,
          operators: OPERATORS_IS,
          fullPath: this.rootPageFullPath,
        });
      }

      if (!this.isGroup) {
        tokens.push({
          type: TOKEN_TYPE_RELEASE,
          title: TOKEN_TITLE_RELEASE,
          icon: 'rocket-launch',
          token: ReleaseToken,
          fetchReleases: this.fetchReleases,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-work-items-recent-tokens-release`,
        });
      }

      if (!this.workItemType) {
        tokens.push({
          type: TOKEN_TYPE_TYPE,
          title: TOKEN_TITLE_TYPE,
          icon: 'work-item-issue',
          unique: true,
          token: WorkItemTypeToken,
          operators: OPERATORS_IS_NOT_OR,
          multiSelect: true,
          fetchWorkItemTypes: this.fetchWorkItemTypes,
        });
      }

      if (this.isLoggedIn) {
        tokens.push({
          type: TOKEN_TYPE_CONFIDENTIAL,
          title: TOKEN_TITLE_CONFIDENTIAL,
          icon: 'eye-slash',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            { icon: 'eye-slash', value: 'yes', title: __('Yes') },
            { icon: 'eye', value: 'no', title: __('No') },
          ],
        });

        tokens.push({
          type: TOKEN_TYPE_MY_REACTION,
          title: TOKEN_TITLE_MY_REACTION,
          icon: 'thumb-up',
          token: EmojiToken,
          unique: true,
          fetchEmojis: this.fetchEmojis,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-my_reaction`,
        });

        tokens.push({
          type: TOKEN_TYPE_SUBSCRIBED,
          title: TOKEN_TITLE_SUBSCRIBED,
          icon: 'notifications',
          token: GlFilteredSearchToken,
          unique: true,
          operators: OPERATORS_IS,
          options: [
            {
              icon: 'notifications',
              value: 'EXPLICITLY_SUBSCRIBED',
              title: __('Explicitly subscribed'),
            },
            {
              icon: 'notifications-off',
              value: 'EXPLICITLY_UNSUBSCRIBED',
              title: __('Explicitly unsubscribed'),
            },
          ],
        });
      }

      if (!this.withTabs) {
        tokens.push({
          type: TOKEN_TYPE_STATE,
          title: TOKEN_TITLE_STATE,
          icon: 'issue-open-m',
          unique: true,
          token: GlFilteredSearchToken,
          operators: OPERATORS_IS,
          options: [
            { value: STATUS_ALL, title: __('Any') },
            { value: STATUS_OPEN, title: __('Open') },
            { value: STATUS_CLOSED, title: __('Closed') },
          ],
        });
      }

      if (this.hasIssueDateFilterFeature) {
        tokens.push({
          type: TOKEN_TYPE_CLOSED,
          title: TOKEN_TITLE_CLOSED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          type: TOKEN_TYPE_CREATED,
          title: TOKEN_TITLE_CREATED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          type: TOKEN_TYPE_DUE_DATE,
          title: TOKEN_TITLE_DUE_DATE,
          icon: 'calendar',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          type: TOKEN_TYPE_UPDATED,
          title: TOKEN_TITLE_UPDATED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });
      }

      if (this.canReadCrmOrganization) {
        tokens.push({
          type: TOKEN_TYPE_ORGANIZATION,
          title: TOKEN_TITLE_ORGANIZATION,
          icon: 'organization',
          token: CrmOrganizationToken,
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-crm-organizations`,
          operators: OPERATORS_IS,
          unique: true,
        });
      }

      if (this.canReadCrmContact) {
        tokens.push({
          type: TOKEN_TYPE_CONTACT,
          title: TOKEN_TITLE_CONTACT,
          icon: 'user',
          token: CrmContactToken,
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-crm-contacts`,
          operators: OPERATORS_IS,
          unique: true,
        });
      }

      tokens.push({
        type: TOKEN_TYPE_PARENT,
        title: TOKEN_TITLE_PARENT,
        icon: 'work-item-parent',
        token: WorkItemParentToken,
        fullPath: this.rootPageFullPath,
        isProject: !this.isGroup,
        recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-parent`,
        operators: OPERATORS_IS_NOT,
        unique: true,
        idProperty: 'id',
      });

      if (this.eeSearchTokens.length) {
        tokens.push(...this.eeSearchTokens);
      }

      tokens.sort((a, b) => a.title.localeCompare(b.title));

      return tokens;
    },
    showPaginationControls() {
      return !this.isLoading && (this.pageInfo.hasNextPage || this.pageInfo.hasPreviousPage);
    },
    showPageSizeSelector() {
      return this.workItems.length > 0;
    },
    showWorkItemByEmail() {
      return Boolean(this.canCreateWorkItem && !this.isGroup && this.newWorkItemEmailAddress);
    },
    sortOptions() {
      return getSortOptions({
        hasBlockedIssuesFeature: this.hasBlockedIssuesFeature,
        hasIssuableHealthStatusFeature: this.hasIssuableHealthStatusFeature,
        hasIssueWeightsFeature: this.hasIssueWeightsFeature,
        hasManualSort: !this.isEpicsList,
        hasStatusFeature: this.hasStatusFeature && !this.isEpicsList && !this.isServiceDeskList,
        hasStartDate: true,
        hasPriority: !this.isEpicsList,
        hasMilestoneDueDate: true,
        hasLabelPriority: !this.isEpicsList,
        hasWeight: !this.isEpicsList,
      });
    },
    tabCounts() {
      const { all, closed, opened } = this.workItemStateCounts;
      return {
        [STATUS_OPEN]: opened,
        [STATUS_CLOSED]: closed,
        [STATUS_ALL]: all,
      };
    },
    urlFilterParams() {
      return convertToUrlParams(this.filterTokens, {
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
      });
    },
    urlParams() {
      return {
        sort: urlSortParams[this.sortKey],
        state: this.state,
        ...this.urlFilterParams,
        first_page_size: this.pageParams.firstPageSize,
        last_page_size: this.pageParams.lastPageSize,
        page_after: this.pageParams.afterCursor ?? undefined,
        page_before: this.pageParams.beforeCursor ?? undefined,
      };
    },
    activeWorkItemType() {
      const activeWorkItemTypeName =
        typeof this.activeItem?.workItemType === 'object'
          ? this.activeItem?.workItemType?.name
          : this.activeItem?.workItemType;
      return this.workItemType || activeWorkItemTypeName;
    },
    tabs() {
      if (this.withTabs) {
        return this.$options.issuableListTabs;
      }
      return [];
    },
    enableClientSideBoardsExperiment() {
      return this.glFeatures.workItemsClientSideBoards;
    },
    isPlanningViewsEnabled() {
      return this.glFeatures.workItemPlanningView || !this.withTabs;
    },
    preselectedWorkItemType() {
      return this.isEpicsList ? WORK_ITEM_TYPE_NAME_EPIC : WORK_ITEM_TYPE_NAME_ISSUE;
    },
    hiddenMetadataKeys() {
      return this.displaySettingsSoT?.namespacePreferences?.hiddenMetadataKeys || [];
    },
    canExport() {
      return !this.isGroup && this.isLoggedIn && this.workItems.length > 0;
    },
    currentTabCount() {
      return this.tabCounts[this.state] ?? 0;
    },
    isManualOrdering() {
      return this.sortKey === RELATIVE_POSITION_ASC;
    },
    parentId() {
      return this.apiFilterParams?.hierarchyFilters?.parentIds?.[0] || null;
    },
    newIssueDropdownQueryVariables() {
      return {
        fullPath: this.rootPageFullPath,
      };
    },
    showProjectNewWorkItem() {
      if (this.workItemPlanningViewEnabled) {
        // In CE, groups cannot enable create_work_items, so showNewWorkItem is always false (only enabled in EE).
        // However, we need to show the button for CE groups with projects (!hasEpicsFeature indicates CE).
        return (this.isGroup && this.hasProjects && !this.hasEpicsFeature) || this.showNewWorkItem;
      }
      return this.showNewWorkItem && !this.isGroupIssuesList;
    },
    showGroupNewWorkItem() {
      return this.isGroupIssuesList && this.hasProjects;
    },
    workItemTotalStateCount() {
      if (this.workItemsCount === null) {
        return '';
      }
      return n__('WorkItem|%d item', 'WorkItem|%d items', formatNumber(this.workItemsCount));
    },
    workItemTypeId() {
      const workItemTypeName = this.workItemType || WORK_ITEM_TYPE_NAME_ISSUE;
      return (
        this.workItemTypes?.find((workItemType) => workItemType.name === workItemTypeName)?.id || ''
      );
    },
    shouldLoad() {
      return !this.isInitialLoadComplete || (!this.isSortKeyInitialized && !this.error);
    },
    isBulkEditDisabled() {
      return this.showBulkEditSidebar || this.workItems.length === 0;
    },
    preferencesChanged() {
      if (!this.initialPreferences) return false;

      const currentPreferences = {
        hiddenMetadataKeys: this.displaySettingsSoT?.namespacePreferences?.hiddenMetadataKeys ?? [],
      };
      const viewPreferences = {
        hiddenMetadataKeys:
          this.initialViewDisplaySettings?.namespacePreferences?.hiddenMetadataKeys ?? [],
      };
      const comparePreferences = this.isSavedView ? viewPreferences : this.initialPreferences;

      return !isEqual(currentPreferences, comparePreferences);
    },
    filtersChanged() {
      const filteredTokens = this.filterTokens
        .filter((token) => {
          if (token.type === 'filtered-search-term') {
            return Boolean(token.value?.data);
          }

          return true;
        })
        .map(({ id, ...rest }) => rest);

      const compareFilters = !this.isSavedView
        ? this.allItemsDefaultFilterTokens
        : this.initialViewTokens;

      return !isEqual(filteredTokens, compareFilters);
    },
    sortChanged() {
      const compareSort = !this.isSavedView ? this.initialSortKey : this.initialViewSortKey;
      return this.sortKey !== compareSort;
    },
    allItemsDefaultFilterTokens() {
      return [
        {
          type: TOKEN_TYPE_STATE,
          value: {
            data: STATUS_OPEN,
            operator: OPERATOR_IS,
          },
        },
      ];
    },
    viewConfigChanged() {
      return this.filtersChanged || this.sortChanged || this.preferencesChanged;
    },
    savedViewDraftStorageKey() {
      return `${this.rootPageFullPath}-saved-view-${this.$route.params.view_id}`;
    },
    viewDraftData() {
      return {
        filterTokens: this.filterTokens,
        sortKey: this.sortKey,
        displaySettings: this.localDisplaySettings,
      };
    },
    isSubscriptionLimitReached() {
      return (
        this.subscribedSavedViewLimit &&
        this.subscribedSavedViews.length >= this.subscribedSavedViewLimit
      );
    },
  },
  watch: {
    eeWorkItemUpdateCount() {
      // Only reset isInitialLoadComplete when there's no issues to minimize unmounting IssuableList
      if (!this.hasWorkItems) {
        this.isInitialLoadComplete = false;
      }
      this.$apollo.queries.workItemStateCounts.refetch();
      this.$apollo.queries.workItemsFull.refetch();
      this.$apollo.queries.workItemsSlim.refetch();
      this.$apollo.queries.hasWorkItems.refetch();
      this.$apollo.queries.workItemsCount.refetch();
    },
    $route(newValue, oldValue) {
      if (newValue.fullPath !== oldValue.fullPath && !this.isSavedView) {
        this.updateData(getParameterByName(PARAM_SORT));
      }
      if (newValue.query[DETAIL_VIEW_QUERY_PARAM_NAME] && !this.detailLoading) {
        this.checkDrawerParams();
      } else {
        this.activeItem = null;
      }
      if (this.isSavedView) this.restoreViewDraft();
    },
    isGroup(value) {
      if (this.isPlanningViewsEnabled && value) {
        initWorkItemsFeedback({
          feedbackIssue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/579558',
          feedbackIssueText: __('Share feedback on the experience'),
          badgeContent: __(
            'All your work items are now in one place, making them easier to manage.',
          ),
          badgeTitle: __('New unified list'),
          badgePopoverTitle: __('New unified work items list'),
          featureName: FEATURE_NAME,
          expiry: CONSOLIDATED_LIST_FEEDBACK_PROMPT_EXPIRY,
        });
      }
    },
    eeSearchTokens() {
      if (this.isSavedView && this.savedView !== null) {
        const draft = localStorage.getItem(this.savedViewDraftStorageKey);
        const tokens = this.getFilterTokensFromSavedView(this.savedView.filters);
        this.initialViewTokens = tokens;
        if (draft) {
          this.restoreViewDraft();
        } else {
          this.filterTokens = tokens;
        }
      }
    },
    displaySettings: {
      immediate: true,
      handler(value) {
        if (!this.initialPreferences && value) {
          this.initialPreferences = {
            commonPreferences: {
              shouldOpenItemsInSidePanel: value.commonPreferences?.shouldOpenItemsInSidePanel,
            },
            namespacePreferences: {
              hiddenMetadataKeys: value.namespacePreferences?.hiddenMetadataKeys ?? [],
            },
          };
        }
        if (isEmpty(this.localDisplaySettings) || !this.isSavedView) {
          this.localDisplaySettings = { ...this.value };
        }
      },
    },
  },
  created() {
    if (this.isSavedView) {
      this.pageParams = getInitialPageParams(this.pageSize);
    } else {
      this.updateData(getParameterByName(PARAM_SORT));
      this.addStateToken();
    }
    this.autocompleteCache = new AutocompleteCache();
    window.addEventListener('popstate', this.checkDrawerParams);
    this.releasesCache = [];
    this.areReleasesFetched = false;
  },
  mounted() {
    setPageFullWidth();
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.checkDrawerParams);
    setPageDefaultWidth();
  },
  methods: {
    createWorkItemQuery(query) {
      return {
        query,
        context: {
          featureCategory: 'portfolio_management',
        },
        variables() {
          return this.queryVariables;
        },
        update(data) {
          return data?.namespace?.workItems.nodes ?? [];
        },
        skip() {
          return isEmpty(this.pageParams) || this.metadataLoading || this.savedViewNotFound;
        },
        result({ data }) {
          this.namespaceId = data?.namespace?.id;
          this.handleListDataResults(data);
        },
        error(error) {
          this.error = s__(
            'WorkItem|Something went wrong when fetching work items. Please try again.',
          );
          Sentry.captureException(error);
        },
      };
    },
    getFilterTokensFromSavedView(savedViewFilters) {
      const tokens = getSavedViewFilterTokens(savedViewFilters, {
        includeStateToken: true,
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
        convertTypeTokens: true,
      });
      const availableTokenTypes = this.searchTokens.map((token) => token.type);
      return tokens.filter((token) => availableTokenTypes.includes(token.type));
    },

    async handleLocalDisplayPreferencesUpdate(newSettings) {
      this.localDisplaySettings = {
        ...this.localDisplaySettings,
        namespacePreferences: {
          hiddenMetadataKeys: [...newSettings.hiddenMetadataKeys],
        },
      };
      this.persistDraft();
    },
    handleListDataResults(listData) {
      this.pageInfo = listData?.namespace?.workItems.pageInfo ?? {};

      if (listData?.namespace) {
        document.title = this.calculateDocumentTitle(listData);
      }
      if (!this.withTabs) {
        this.isInitialLoadComplete = true;
      }
      this.checkDrawerParams();
    },
    handleToggle(item) {
      if (item && this.activeItem?.iid === item.iid) {
        this.activeItem = null;
        const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);
        if (queryParam) {
          updateHistory({
            url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
          });
        }
      } else {
        this.activeItem = item;
      }
    },
    calculateDocumentTitle(data) {
      const middleCrumb = data.namespace.name;
      if (this.isServiceDeskList) {
        return `${__('Service Desk')} · ${middleCrumb} · GitLab`;
      }
      if (this.isPlanningViewsEnabled) {
        return `${s__('WorkItem|Work items')} · ${middleCrumb} · GitLab`;
      }
      if (this.isGroup && this.isEpicsList) {
        return `${__('Epics')} · ${middleCrumb} · GitLab`;
      }
      if (this.isGroup && !this.isGroupIssuesList) {
        return `${s__('WorkItem|Work items')} · ${middleCrumb} · GitLab`;
      }
      return `${__('Issues')} · ${middleCrumb} · GitLab`;
    },
    fetchEmojis(search) {
      return this.autocompleteCache.fetch({
        url: this.autocompleteAwardEmojisPath,
        cacheName: 'emojis',
        searchProperty: 'name',
        search,
      });
    },
    fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      return this.$apollo
        .query({
          query: searchLabelsQuery,
          variables: { fullPath: this.rootPageFullPath, search, isProject: !this.isGroup },
          fetchPolicy,
        })
        .then(({ data }) => {
          // TODO remove once we can search by title-only on the backend
          // https://gitlab.com/gitlab-org/gitlab/-/issues/346353
          const labels = data[this.namespace]?.labels.nodes;
          return labels.filter((label) => label.title.toLowerCase().includes(search.toLowerCase()));
        });
    },
    fetchLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search);
    },
    fetchLatestLabels(search) {
      return this.fetchLabelsWithFetchPolicy(search, fetchPolicies.NETWORK_ONLY);
    },
    getStatus(issue) {
      return issue.state === STATE_CLOSED ? __('Closed') : undefined;
    },
    async handleBulkEditSuccess(event) {
      this.showBulkEditSidebar = false;
      this.refetchItems(event);
      if (event?.toastMessage) {
        this.$toast.show(event.toastMessage);
      }
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }

      this.state = state;
      this.pageParams = getInitialPageParams(this.pageSize);

      this.updateRouterQueryParams();
    },
    handleFilter(tokens) {
      this.filterTokens = tokens;
      this.hasStateToken = this.checkIfStateTokenExists();
      this.updateState(tokens);
      this.pageParams = getInitialPageParams(this.pageSize);

      this.updateRouterQueryParams();
      this.persistDraft();
    },
    updateRouterQueryParams() {
      if (this.isSavedView) {
        return;
      }

      this.$router.push({ query: this.urlParams }).catch((error) => {
        if (error.name !== 'NavigationDuplicated') {
          throw error;
        }
      });
    },
    handleNextPage() {
      this.pageParams = {
        afterCursor: this.pageInfo.endCursor,
        firstPageSize: this.pageSize,
      };
      scrollUp();

      this.updateRouterQueryParams();
    },
    handlePageSizeChange(pageSize) {
      this.pageSize = pageSize;
      this.pageParams = getInitialPageParams(pageSize);
      scrollUp();

      this.updateRouterQueryParams();
    },
    handlePreviousPage() {
      this.pageParams = {
        beforeCursor: this.pageInfo.startCursor,
        lastPageSize: this.pageSize,
      };
      scrollUp();

      this.updateRouterQueryParams();
    },
    showIssueRepositioningMessage() {
      createAlert({
        message: s__(
          'WorkItems|Sort order rebalancing in progress. Reordering is temporarily disabled.',
        ),
        variant: VARIANT_INFO,
      });
    },
    handleSort(sortKey) {
      if (this.sortKey === sortKey) {
        return;
      }

      if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
        this.showIssueRepositioningMessage();
        return;
      }

      this.sortKey = sortKey;
      this.pageParams = getInitialPageParams(this.pageSize);

      if (this.isLoggedIn) {
        this.saveSortPreference(sortKey);
      }

      this.updateRouterQueryParams();
      this.persistDraft();
    },
    async saveSortPreference(sortKey) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateWorkItemListUserPreference,
          variables: {
            namespace: this.rootPageFullPath,
            workItemTypeId: this.workItemTypeId,
            sort: sortKey,
          },
          update: (
            cache,
            {
              data: {
                workItemUserPreferenceUpdate: { userPreferences },
              },
            },
          ) => {
            if (!userPreferences) {
              return;
            }
            cache.updateQuery(
              {
                query: getUserWorkItemsPreferences,
                variables: {
                  namespace: this.rootPageFullPath,
                  workItemTypeId: this.workItemTypeId,
                },
              },
              (existingData) =>
                produce(existingData, (draftData) => {
                  draftData.currentUser.workItemPreferencesWithType.sort = userPreferences.sort;
                }),
            );
          },
        });
        if (data?.workItemUserPreferenceUpdate?.errors?.length) {
          throw new Error(data.workItemUserPreferenceUpdate.errors);
        }
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    deleteItem() {
      this.activeItem = null;
      this.refetchItems({ refetchCounts: true });
    },
    handleStatusChange(workItem) {
      if (this.state === STATUS_ALL) {
        return;
      }

      if (this.state !== workItem.state) {
        this.refetchItems({ refetchCounts: true });
      }
    },
    async refetchItems({ refetchCounts = false } = {}) {
      if (refetchCounts) {
        this.$apollo.queries.workItemStateCounts.refetch();
      }

      // evict the namespace's workItems cache to force a full refetch
      const { cache } = this.$apollo.provider.defaultClient;
      cache.evict({
        id: cache.identify({ __typename: TYPENAME_NAMESPACE, id: this.namespaceId }),
        fieldName: 'workItems',
      });
      cache.gc();
    },
    updateData(sort) {
      const firstPageSize = getParameterByName(PARAM_FIRST_PAGE_SIZE);
      const lastPageSize = getParameterByName(PARAM_LAST_PAGE_SIZE);
      const state = getParameterByName(PARAM_STATE);

      let sortKey = deriveSortKey({ sort, state });

      if (this.isIssueRepositioningDisabled && sortKey === RELATIVE_POSITION_ASC) {
        this.showIssueRepositioningMessage();
        sortKey = state === STATUS_CLOSED ? UPDATED_DESC : CREATED_DESC;
      }

      const tokens = getFilterTokens(window.location.search, {
        includeStateToken: !this.withTabs,
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
        convertTypeTokens: true,
      });
      this.filterTokens = groupMultiSelectFilterTokens(tokens, this.searchTokens);

      if (!this.hasStateToken && this.state === STATUS_ALL) {
        this.filterTokens = this.filterTokens.filter(
          (filterToken) => filterToken.type !== TOKEN_TYPE_STATE,
        );
      }

      this.pageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        getParameterByName(PARAM_PAGE_AFTER) ?? undefined,
        getParameterByName(PARAM_PAGE_BEFORE) ?? undefined,
      );

      // Trigger pageSize UI component update based on URL changes
      this.pageSize = this.pageParams.firstPageSize;
      this.sortKey = sortKey;
      this.state = state || STATUS_OPEN;
    },
    checkDrawerParams() {
      const queryParam = getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME);

      if (!queryParam) {
        this.activeItem = null;
        return;
      }

      const params = JSON.parse(atob(queryParam));
      if (params.id) {
        const issue = this.workItems.find((i) => getIdFromGraphQLId(i.id) === params.id);
        if (issue) {
          this.activeItem = {
            ...issue,
            // we need fullPath here to prevent cache invalidation
            fullPath: params.full_path,
          };
        } else {
          updateHistory({
            url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]),
          });
        }
      }
    },
    updateState(tokens) {
      if (!this.withTabs) {
        this.state =
          tokens.find((token) => token.type === TOKEN_TYPE_STATE)?.value.data || STATUS_ALL;
      }
    },
    addStateToken() {
      this.hasStateToken = this.checkIfStateTokenExists();
      if (!this.withTabs && !this.hasStateToken) {
        this.filterTokens.push({
          type: TOKEN_TYPE_STATE,
          value: {
            data: STATUS_OPEN,
            operator: OPERATOR_IS,
          },
        });
      }
    },
    checkIfStateTokenExists() {
      return this.filterTokens.some((filterToken) => filterToken.type === TOKEN_TYPE_STATE);
    },
    handleWorkItemCreated() {
      this.refetchItems({ refetchCounts: true });
    },
    fetchReleases(search) {
      if (this.areReleasesFetched) {
        const data = search
          ? fuzzaldrinPlus.filter(this.releasesCache, search, { key: 'tag' })
          : this.releasesCache.slice(0, 10);
        return Promise.resolve(data);
      }

      return axios
        .get(this.releasesPath)
        .then(({ data }) => {
          this.releasesCache = data;
          this.areReleasesFetched = true;
          return data.slice(0, 10);
        })
        .catch(() => {
          this.error = s__('WorkItem|Something went wrong while fetching items. Please try again.');
          return [];
        });
    },
    handleReorder({ newIndex, oldIndex }) {
      if (newIndex === oldIndex) return Promise.resolve();

      const workItemToMove = this.workItems[oldIndex];

      const remainingItems = this.workItems.filter((_, index) => index !== oldIndex);

      let moveBeforeId = null;
      let moveAfterId = null;

      if (newIndex === 0) {
        // Moving to beginning
        moveBeforeId = null;
        moveAfterId = remainingItems[0]?.id || null;
      } else if (newIndex >= remainingItems.length) {
        // Moving to end
        moveAfterId = null;
        moveBeforeId = remainingItems[remainingItems.length - 1]?.id || null;
      } else {
        // Moving between items
        moveAfterId = remainingItems[newIndex - 1]?.id || null;
        moveBeforeId = remainingItems[newIndex]?.id || null;
      }

      const input = { id: workItemToMove.id };
      if (moveBeforeId) input.moveBeforeId = moveBeforeId;
      if (moveAfterId) input.moveAfterId = moveAfterId;

      return this.$apollo
        .mutate({
          mutation: workItemsReorderMutation,
          variables: { input },
          update: (cache) => {
            this.updateWorkItemsCache(cache, oldIndex, newIndex);
          },
        })
        .then(({ data }) => {
          if (data?.workItemsReorder?.errors?.length > 0) {
            throw new Error(data.workItemsReorder.errors.join(', '));
          }
          return data;
        })
        .catch((error) => {
          this.error = s__('WorkItem|An error occurred while reordering work items.');
          Sentry.captureException(error);
          throw error;
        });
    },
    updateWorkItemsCache(cache, oldIndex, newIndex) {
      cache.updateQuery(
        {
          query: this.$apollo.queries.workItemsFull.options.query,
          variables: this.queryVariables,
        },
        (existingData) => {
          if (!existingData?.namespace?.workItems?.nodes) {
            return existingData;
          }

          const workItems = [...existingData.namespace.workItems.nodes];

          if (oldIndex >= 0 && oldIndex < workItems.length) {
            const [movedItem] = workItems.splice(oldIndex, 1);
            if (movedItem) {
              workItems.splice(newIndex, 0, movedItem);
            }
          }

          const newData = {
            ...existingData,
            namespace: {
              ...existingData.namespace,
              workItems: {
                ...existingData.namespace.workItems,
                nodes: workItems,
              },
            },
          };

          return newData;
        },
      );
    },
    isDirectChildOfWorkItem(workItem) {
      if (!workItem) {
        return false;
      }

      return findHierarchyWidget(workItem)?.parent?.id !== this.parentId;
    },
    extractProjects(data) {
      return data?.group?.projects?.nodes;
    },
    fetchWorkItemTypes() {
      return this.$apollo.query({
        query: namespaceWorkItemTypesQuery,
        variables: {
          fullPath: this.rootPageFullPath,
          onlyAvailable: this.isProject,
        },
      });
    },
    resetToDefaultView() {
      this.filterTokens = [
        {
          type: TOKEN_TYPE_STATE,
          value: {
            data: STATUS_OPEN,
            operator: OPERATOR_IS,
          },
        },
      ];
      this.state = STATUS_OPEN;
      this.pageParams = getInitialPageParams(this.pageSize);
      this.sortKey = CREATED_DESC;

      this.$router.push({ name: ROUTES.index, query: this.urlParams }).catch((error) => {
        if (error.name !== 'NavigationDuplicated') {
          throw error;
        }
      });
    },
    async confirmViewChanges() {
      const title = sprintf(s__('WorkItem|Save changes to %{viewName}?'), {
        viewName: this.savedView?.name,
      });

      const message = `
        <span class="saved-view-confirm-modal">
          ${s__('WorkItem|Changes will be applied for anyone else who has access to the view.')}
        </span>
      `;

      const confirmation = await confirmAction(null, {
        title,
        modalHtmlMessage: message,
        primaryBtnText: s__('WorkItem|Save changes'),
      });

      if (confirmation) {
        const mutationKey = 'workItemSavedViewUpdate';
        try {
          const { data } = await saveSavedView({
            isEdit: true,
            isForm: false,
            namespacePath: this.rootPageFullPath,
            id: this.savedView?.id,
            name: this.savedView?.name,
            description: this.savedView?.description,
            isPrivate: this.savedView?.isPrivate,
            filters: this.apiFilterParams,
            displaySettings: this.displaySettingsSoT?.namespacePreferences || {},
            sort: this.sortKey,
            userPermissions: this.savedView?.userPermissions,
            subscribed: this.savedView?.subscribed,
            mutationKey,
            apolloClient: this.$apollo,
          });

          if (data[mutationKey].errors?.length) {
            this.error = s__('WorkItem|Something went wrong while saving the view');
            return;
          }

          this.$toast.show(s__('WorkItem|View has been saved.'));
          this.clearLocalSavedViewsConfig();
        } catch (e) {
          Sentry.captureException(e);
          this.error = s__('WorkItem|Something went wrong while saving the view');
        }
      }
    },
    async resetToViewDefaults() {
      this.filterTokens = [...this.initialViewTokens];
      this.sortKey = this.initialViewSortKey;
      this.localDisplaySettings = this.initialViewDisplaySettings;
      this.clearLocalSavedViewsConfig();
    },
    restoreViewDraft() {
      const draft = localStorage.getItem(this.savedViewDraftStorageKey);
      if (!draft) return;

      const parsedData = JSON.parse(draft);

      this.filterTokens = parsedData.filterTokens;
      this.sortKey = parsedData.sortKey;
      this.localDisplaySettings = parsedData.displaySettings;
    },
    handleError(error, message) {
      Sentry.captureException(error);

      // if custom message is provided, use it
      if (message) this.error = message;
    },
    persistDraft() {
      if (!this.isSavedView) return;

      if (!this.viewConfigChanged) {
        this.clearLocalSavedViewsConfig();
        return;
      }

      localStorage.setItem(this.savedViewDraftStorageKey, JSON.stringify(this.viewDraftData));
    },
    clearLocalSavedViewsConfig() {
      localStorage.removeItem(this.savedViewDraftStorageKey);
    },
  },
  constants: {
    METADATA_KEYS,
  },
};
</script>

<template>
  <gl-loading-icon v-if="shouldLoad" class="gl-mt-5" size="lg" />

  <div
    v-else-if="shouldShowList"
    :class="{ 'work-item-list-container': isPlanningViewsEnabled && !isServiceDeskList }"
  >
    <user-callout-dismisser
      v-if="isPlanningViewsEnabled && workItemsSavedViewsEnabled"
      feature-name="work_items_onboarding_modal"
    >
      <template #default="{ dismiss, shouldShowCallout }">
        <work-items-onboarding-modal v-if="shouldShowCallout" @close="dismiss" />
      </template>
    </user-callout-dismisser>
    <div v-if="showLocalBoard">
      <local-board :work-item-list-data="workItems" @back="showLocalBoard = false" />
    </div>
    <template v-else>
      <work-item-drawer
        v-if="workItemDrawerEnabled"
        :active-item="activeItem"
        :open="isItemSelected"
        :issuable-type="activeWorkItemType"
        click-outside-exclude-selector=".issuable-list"
        @close="activeItem = null"
        @addChild="refetchItems"
        @workItemDeleted="deleteItem"
        @work-item-updated="handleStatusChange"
      />
      <info-banner v-if="isInfoBannerVisible" />
      <issuable-list
        :active-issuable="activeItem"
        :current-tab="state"
        :default-page-size="pageSize"
        :error="isPlanningViewsEnabled ? undefined : error"
        :has-next-page="pageInfo.hasNextPage"
        :has-previous-page="pageInfo.hasPreviousPage"
        :initial-filter-value="filterTokens"
        :initial-sort-by="sortKey"
        :issuables="workItems"
        :issuables-loading="isLoading"
        :is-manual-ordering="isManualOrdering"
        :show-bulk-edit-sidebar="showBulkEditSidebar"
        label-filter-param="label_name"
        :namespace="rootPageFullPath"
        :full-path="rootPageFullPath"
        recent-searches-storage-key="issues"
        :search-tokens="searchTokens"
        show-filtered-search-friendly-text
        :show-page-size-selector="showPageSizeSelector"
        :show-pagination-controls="showPaginationControls"
        show-work-item-type-icon
        :sort-options="sortOptions"
        sync-filter-and-sort
        :tab-counts="tabCounts"
        :tabs="tabs"
        use-keyset-pagination
        :prevent-redirect="workItemDrawerEnabled"
        :detail-loading="detailLoading"
        :hidden-metadata-keys="hiddenMetadataKeys"
        :always-allow-custom-empty-state="isPlanningViewsEnabled"
        @click-tab="handleClickTab"
        @dismiss-alert="error = undefined"
        @filter="handleFilter"
        @next-page="handleNextPage"
        @page-size-change="handlePageSizeChange"
        @previous-page="handlePreviousPage"
        @sort="handleSort"
        @select-issuable="handleToggle"
        @reorder="handleReorder"
      >
        <template #user-preference>
          <work-item-user-preferences
            :namespace-preferences="displaySettingsSoT.namespacePreferences"
            :common-preferences="displaySettings.commonPreferences"
            :full-path="rootPageFullPath"
            :is-epics-list="isEpicsList"
            :is-group="isGroup"
            :is-service-desk-list="isServiceDeskList"
            :work-item-type-id="workItemTypeId"
            :sort-key="sortKey"
            :prevent-auto-submit="isSavedView"
            @local-update="handleLocalDisplayPreferencesUpdate"
          />
        </template>
        <template v-if="!isPlanningViewsEnabled && !isServiceDeskList" #nav-actions>
          <div class="gl-flex gl-justify-end gl-gap-3">
            <gl-button
              v-if="enableClientSideBoardsExperiment"
              data-testid="show-local-board-button"
              @click="showLocalBoard = true"
            >
              {{ __('Launch board') }}
            </gl-button>
            <gl-button
              v-if="allowBulkEditing"
              :disabled="isBulkEditDisabled"
              data-testid="bulk-edit-start-button"
              @click="showBulkEditSidebar = true"
            >
              {{ __('Bulk edit') }}
            </gl-button>
            <create-work-item-modal
              v-if="showProjectNewWorkItem"
              :always-show-work-item-type-select="!isEpicsList"
              :creation-context="$options.CREATION_CONTEXT_LIST_ROUTE"
              :full-path="rootPageFullPath"
              :is-group="isGroup"
              :preselected-work-item-type="preselectedWorkItemType"
              :is-epics-list="isEpicsList"
              :create-source="$options.WORK_ITEM_CREATE_SOURCES.WORK_ITEM_LIST"
              @workItemCreated="handleWorkItemCreated"
            />
            <new-resource-dropdown
              v-if="showGroupNewWorkItem"
              :query="$options.searchProjectsQuery"
              :query-variables="newIssueDropdownQueryVariables"
              :extract-projects="extractProjects"
              :group-id="groupId"
            />
            <work-item-list-actions
              :can-export="canExport"
              :show-work-item-by-email-button="showWorkItemByEmail"
              :work-item-count="currentTabCount"
              :query-variables="csvExportQueryVariables"
              :full-path="rootPageFullPath"
              :url-params="urlParams"
              :is-epics-list="isEpicsList"
              :is-group-issues-list="isGroupIssuesList"
            />
          </div>
        </template>

        <template v-if="isPlanningViewsEnabled && !isServiceDeskList" #list-header>
          <div v-if="error" class="gl-mt-5">
            <gl-alert variant="danger" :dismissible="hasWorkItems" @dismiss="error = undefined">
              {{ error }}
            </gl-alert>
          </div>
          <template v-if="!workItemsSavedViewsEnabled">
            <work-item-list-heading>
              <div class="gl-flex gl-justify-end gl-gap-3">
                <gl-button
                  v-if="enableClientSideBoardsExperiment"
                  data-testid="show-local-board-button"
                  @click="showLocalBoard = true"
                >
                  {{ __('Launch board') }}
                </gl-button>
                <gl-button
                  v-if="allowBulkEditing"
                  :disabled="isBulkEditDisabled"
                  data-testid="bulk-edit-start-button"
                  @click="showBulkEditSidebar = true"
                >
                  {{ __('Bulk edit') }}
                </gl-button>
                <create-work-item-modal
                  v-if="showProjectNewWorkItem"
                  :always-show-work-item-type-select="!isEpicsList"
                  :creation-context="$options.CREATION_CONTEXT_LIST_ROUTE"
                  :full-path="rootPageFullPath"
                  :is-group="isGroup"
                  :preselected-work-item-type="preselectedWorkItemType"
                  :is-epics-list="isEpicsList"
                  :show-project-selector="!hasEpicsFeature"
                  @workItemCreated="handleWorkItemCreated"
                />
                <new-resource-dropdown
                  v-if="isGroupIssuesList"
                  :query="$options.searchProjectsQuery"
                  :query-variables="newIssueDropdownQueryVariables"
                  :extract-projects="extractProjects"
                  :group-id="groupId"
                />
                <work-item-list-actions
                  :can-export="canExport"
                  :show-work-item-by-email-button="showWorkItemByEmail"
                  :work-item-count="workItemsCount"
                  :query-variables="csvExportQueryVariables"
                  :full-path="rootPageFullPath"
                  :url-params="urlParams"
                  :is-epics-list="isEpicsList"
                  :is-group-issues-list="isGroupIssuesList"
                />
              </div>
            </work-item-list-heading>
          </template>

          <template v-if="workItemsSavedViewsEnabled">
            <work-items-saved-views-selectors
              :selected-saved-view="savedView"
              :full-path="rootPageFullPath"
              :saved-views="subscribedSavedViews"
              :sort-key="sortKey"
              :filters="apiFilterParams"
              :display-settings="displaySettingsSoT.namespacePreferences"
              @reset-to-default-view="resetToDefaultView"
              @error="handleError"
            >
              <template #header-area>
                <work-item-list-actions
                  :can-export="canExport"
                  :show-work-item-by-email-button="showWorkItemByEmail"
                  :work-item-count="currentTabCount"
                  :query-variables="csvExportQueryVariables"
                  :full-path="rootPageFullPath"
                  :url-params="urlParams"
                  :is-epics-list="isEpicsList"
                  :is-group-issues-list="isGroupIssuesList"
                />
                <create-work-item-modal
                  v-if="showProjectNewWorkItem"
                  :always-show-work-item-type-select="!isEpicsList"
                  :creation-context="$options.CREATION_CONTEXT_LIST_ROUTE"
                  :full-path="rootPageFullPath"
                  :is-group="isGroup"
                  :preselected-work-item-type="preselectedWorkItemType"
                  :is-epics-list="isEpicsList"
                  :create-source="$options.WORK_ITEM_CREATE_SOURCES.WORK_ITEM_LIST"
                  @workItemCreated="handleWorkItemCreated"
                />
              </template>
            </work-items-saved-views-selectors>
          </template>
        </template>

        <template v-if="isPlanningViewsEnabled && !isServiceDeskList" #before-list-items>
          <!-- state-count -->
          <div class="gl-border-b gl-flex gl-flex-wrap gl-justify-between gl-gap-y-3 gl-py-3">
            <div class="gl-flex gl-items-center">
              <span data-testid="work-item-count" class="gl-mr-3">{{
                workItemTotalStateCount
              }}</span>
              <gl-button
                v-if="workItemsSavedViewsEnabled && allowBulkEditing"
                size="small"
                category="primary"
                variant="default"
                :disabled="isBulkEditDisabled"
                data-testid="bulk-edit-start-button"
                @click="showBulkEditSidebar = true"
              >
                {{ __('Bulk edit') }}
              </gl-button>
            </div>

            <template v-if="workItemsSavedViewsEnabled">
              <template v-if="!isSavedView">
                <gl-button
                  v-if="viewConfigChanged"
                  size="small"
                  category="primary"
                  variant="default"
                  data-testid="save-view-button"
                  @click="isNewViewModalVisible = true"
                >
                  {{ s__('WorkItem|Save view') }}
                </gl-button>
                <work-items-new-saved-view-modal
                  v-model="isNewViewModalVisible"
                  :full-path="rootPageFullPath"
                  :title="s__('WorkItem|Save view')"
                  :sort-key="sortKey"
                  :filters="apiFilterParams"
                  :display-settings="displaySettingsSoT.namespacePreferences"
                  :show-subscription-limit-warning="isSubscriptionLimitReached"
                  @hide="isNewViewModalVisible = false"
                />
              </template>
              <template v-else>
                <div v-if="viewConfigChanged" class="gl-flex">
                  <gl-button
                    size="small"
                    category="tertiary"
                    class="!gl-text-sm"
                    variant="link"
                    data-testid="reset-view-button"
                    @click="resetToViewDefaults"
                  >
                    {{ s__('WorkItem|Reset to defaults') }}
                  </gl-button>
                  <div class="gl-border-r gl-mx-4 gl-h-full gl-w-1 gl-border-r-subtle"></div>
                  <gl-button
                    size="small"
                    category="primary"
                    variant="default"
                    data-testid="update-view-button"
                    @click="confirmViewChanges"
                  >
                    {{ s__('WorkItem|Save changes') }}
                  </gl-button>
                </div>
              </template>
            </template>
          </div>
        </template>

        <template #timeframe="{ issuable = {} }">
          <issue-card-time-info
            :issue="issuable"
            :is-work-item-list="true"
            :hidden-metadata-keys="hiddenMetadataKeys"
            :detail-loading="detailLoading"
          />
        </template>

        <template #status="{ issuable }">
          {{ getStatus(issuable) }}
        </template>

        <template #statistics="{ issuable = {} }">
          <issue-card-statistics :issue="issuable" />
        </template>

        <template v-if="!error" #empty-state>
          <slot name="list-empty-state" :has-search="hasSearch" :is-open-tab="isOpenTab">
            <template v-if="isServiceDeskList">
              <empty-state-with-any-tickets
                v-if="hasWorkItems"
                :has-search="hasSearch"
                :is-open-tab="isOpenTab"
              />
              <empty-state-without-any-tickets v-else />
            </template>

            <empty-state-with-any-issues
              v-else-if="hasWorkItems"
              :has-search="hasSearch"
              :is-open-tab="isOpenTab"
              :is-epic="isEpicsList"
            >
              <template #new-issue-button>
                <create-work-item-modal
                  v-if="showProjectNewWorkItem"
                  :always-show-work-item-type-select="!isEpicsList"
                  :creation-context="$options.CREATION_CONTEXT_LIST_ROUTE"
                  :full-path="rootPageFullPath"
                  :is-group="isGroup"
                  :preselected-work-item-type="preselectedWorkItemType"
                  :is-epics-list="isEpicsList"
                  :create-source="$options.WORK_ITEM_CREATE_SOURCES.WORK_ITEM_LIST"
                  @workItemCreated="handleWorkItemCreated"
                />
                <new-resource-dropdown
                  v-if="showGroupNewWorkItem"
                  :query="$options.searchProjectsQuery"
                  :query-variables="newIssueDropdownQueryVariables"
                  :extract-projects="extractProjects"
                  :group-id="groupId"
                />
              </template>
            </empty-state-with-any-issues>
            <empty-state-without-any-issues
              v-else
              :show-new-issue-dropdown="showGroupNewWorkItem"
              :has-projects="hasProjects"
            >
              <template #new-issue-button>
                <create-work-item-modal
                  v-if="showProjectNewWorkItem"
                  :always-show-work-item-type-select="!isEpicsList"
                  :creation-context="$options.CREATION_CONTEXT_LIST_ROUTE"
                  :full-path="rootPageFullPath"
                  :is-group="isGroup"
                  :preselected-work-item-type="preselectedWorkItemType"
                  :show-project-selector="!hasEpicsFeature"
                  :create-source="$options.WORK_ITEM_CREATE_SOURCES.WORK_ITEM_LIST"
                  @workItemCreated="handleWorkItemCreated"
                />
              </template>
            </empty-state-without-any-issues>
          </slot>
        </template>

        <template #list-body>
          <slot name="list-body"></slot>
        </template>

        <template #bulk-edit-actions="{ checkedIssuables }">
          <gl-button
            :disabled="!checkedIssuables.length || bulkEditInProgress"
            form="work-item-list-bulk-edit"
            :loading="bulkEditInProgress"
            type="submit"
            variant="confirm"
          >
            {{ __('Update selected') }}
          </gl-button>
          <gl-button class="gl-float-right" @click="showBulkEditSidebar = false">
            {{ __('Cancel') }}
          </gl-button>
        </template>

        <template #sidebar-items="{ checkedIssuables }">
          <div class="work-item-bulk-edit-sidebar-wrapper gl-overflow-y-auto">
            <work-item-bulk-edit-sidebar
              v-if="showBulkEditSidebar"
              :checked-items="checkedIssuables"
              :full-path="rootPageFullPath"
              :is-epics-list="isEpicsList"
              :is-group="isGroup"
              @finish="bulkEditInProgress = false"
              @start="bulkEditInProgress = true"
              @success="handleBulkEditSuccess"
            />
          </div>
        </template>

        <template #health-status="{ issuable = {} }">
          <health-status
            v-if="!hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.HEALTH)"
            :issue="issuable"
          />
        </template>
        <template #custom-status="{ issuable }">
          <slot
            v-if="!hiddenMetadataKeys.includes($options.constants.METADATA_KEYS.STATUS)"
            name="custom-status"
            :issuable="issuable"
          ></slot>
        </template>
        <template v-if="parentId" #title-icons="{ issuable }">
          <span
            v-if="!detailLoading && isDirectChildOfWorkItem(issuable)"
            v-gl-tooltip
            data-testid="sub-child-work-item-indicator"
            :title="__('This item belongs to a descendant of the filtered parent.')"
            class="gl-ml-1 gl-inline-block"
          >
            <gl-icon name="file-tree" variant="subtle" />
          </span>
          <gl-skeleton-loader
            v-if="detailLoading"
            class="gl-ml-1 gl-inline-block"
            :width="20"
            :lines="1"
            equal-width-lines
          />
        </template>
      </issuable-list>
    </template>
  </div>

  <div v-else>
    <slot name="page-empty-state"></slot>
  </div>
</template>
