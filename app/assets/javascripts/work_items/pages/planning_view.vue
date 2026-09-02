<script>
import {
  GlButton,
  GlAlert,
  GlFilteredSearchToken,
  GlIntersectionObserver,
  GlToastMixin,
} from '@gitlab/ui';
import { debounce, isEmpty, isEqual } from 'lodash-es';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import axios from '~/lib/utils/axios_utils';
import { s__, __, n__, formatNumber, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { InternalEvents } from '~/tracking';
import { createAlert, VARIANT_INFO } from '~/alert';
import { TYPENAME_USER, TYPENAME_WORK_ITEMS_TYPE } from '~/graphql_shared/constants';
import { getParameterByName, removeParams, updateHistory } from '~/lib/utils/url_utility';
import {
  STATUS_ALL,
  STATUS_OPEN,
  NAMESPACE_GROUP,
  NAMESPACE_PROJECT,
  STATUS_CLOSED,
} from '~/issues/constants';
import { DEFAULT_PAGE_SIZE, issuableListTabs } from '~/vue_shared/issuable/list/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { fetchPolicies } from '~/lib/graphql';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { AutocompleteCache } from '~/issues/dashboard/utils';
import { setPageFullWidth, setPageDefaultWidth, isLoggedIn } from '~/lib/utils/common_utils';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

import {
  FILTERED_SEARCH_TERM,
  OPERATOR_IS,
  OPERATORS_AFTER_BEFORE,
  OPERATORS_IS,
  OPERATORS_IS_NOT,
  OPERATORS_IS_NOT_OR,
  OPTIONS_NONE_ANY,
  OPTIONS_NONE_ANY_ME,
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

import usersAutocompleteQuery from '~/graphql_shared/queries/users_autocomplete.query.graphql';
import searchMilestonesQuery from '~/vue_shared/components/filtered_search_bar/queries/search_milestones.query.graphql';
import searchLabelsQuery from '~/work_items/list/graphql/search_labels.query.graphql';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import hasWorkItemsQuery from '~/work_items/list/graphql/has_work_items.query.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import namespaceSavedViewQuery from '~/work_items/list/graphql/namespace_saved_view.query.graphql';
import getNamespaceSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';

import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import IssuableTabs from '~/vue_shared/issuable/list/components/issuable_tabs.vue';

import {
  convertLegacyTypeFormat,
  convertOldTypeTokenEnumToGid,
  convertNumberToGid,
  getSortOptions,
  getInitialPageParams,
  isCursorCompatibleWithApi,
  subscribeToSavedView,
  convertToApiParams,
  convertToUrlParams,
  deriveSortKey,
  getFilterTokens,
  groupMultiSelectFilterTokens,
  saveSavedView,
  getSavedViewFilterTokens,
  convertToSearchQuery,
  updateNamespaceDisplaySettings,
} from 'ee_else_ce/work_items/list/utils';

import {
  CREATED_DESC,
  RELATIVE_POSITION_ASC,
  PARAM_SORT,
  UPDATED_DESC,
  ISSUE_REFERENCE,
  urlSortParams,
  PARAM_FIRST_PAGE_SIZE,
  PARAM_LAST_PAGE_SIZE,
  PARAM_PAGE_AFTER,
  PARAM_PAGE_BEFORE,
  PARAM_STATE,
} from '~/work_items/list/constants';
import {
  planningViewAllItemsFilters,
  setPlanningViewAllItemsFilters,
  getSavedViewSessionFilters,
  setSavedViewSessionFilters,
} from '~/work_items/pages/planning_view_state';
import {
  getSavedViewDraft,
  saveSavedViewDraft,
  clearSavedViewDraft,
} from '~/work_items/list/saved_view_draft';
import {
  ALL_ITEMS_DEFAULT_FILTER_TOKENS,
  filtersChanged,
  sortChanged,
  viewModeChanged,
  preferencesChanged,
} from '~/work_items/list/view_change_detection';
import { persistSortPreference } from '~/work_items/list/display_settings_preferences';
import { buildInitialViewState } from '~/work_items/list/saved_view_config';

import searchProjectsQuery from '../list/graphql/search_projects.query.graphql';
import namespaceWorkItemChangesSubscription from '../list/graphql/namespace_work_item_changes.subscription.graphql';
import {
  evictNamespaceWorkItems,
  evictWorkItem,
  groupWorkItemChanges,
  isWorkItemCached,
  mergeWorkItemChangeAction,
} from '../list/graphql/cache_updates';

import SavedViewsNotFoundModal from '../list/components/work_items_saved_views_not_found_modal.vue';
import SavedViewsLimitWarningModal from '../list/components/work_items_saved_views_limit_warning_modal.vue';
import SavedViewsSelectors from '../list/components/work_items_saved_views_selectors.vue';
import ListActions from '../list/components/work_item_list_actions.vue';
import CreateWorkItemModal from '../components/create_work_item_modal.vue';
import EmptyStateWithAnyIssues from '../list/components/empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from '../list/components/empty_state_without_any_issues.vue';
import EmptyStateWithAnyTickets from '../list/components/empty_state_with_any_tickets.vue';
import EmptyStateWithoutAnyTickets from '../list/components/empty_state_without_any_tickets.vue';
import InfoBanner from '../list/components/info_banner.vue';
import NewSavedViewModal from '../list/components/work_items_new_saved_view_modal.vue';
import WorkItemDetailPanel from '../components/work_item_detail_panel.vue';
import WorkItemDisplaySettingsDrawer from '../list/components/work_item_display_settings_drawer.vue';

import {
  WORK_ITEM_TYPE_NAME_TICKET,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  ROUTES,
  WORK_ITEM_CREATE_SOURCES,
  CREATION_CONTEXT_LIST_ROUTE,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  DETAIL_VIEW_DESIGN_VERSION_PARAM_NAME,
  VIEW_CONTEXT,
  VIEW_MODE_LIST,
  VIEW_MODE_BOARD,
  VIEW_MODE_TABLE,
  DISPLAY_SETTINGS_PAGE_ROOT,
  DISPLAY_SETTINGS_PAGE_GROUP_BY,
} from '../constants';

const ListView = () => import('ee_else_ce/work_items/list/list_view.vue');
const BoardView = () => import('~/work_items/board/board_view.vue');
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
const CrmOrganizationToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/crm_organization_token.vue');
const CrmContactToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/crm_contact_token.vue');
const WorkItemParentToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/work_item_parent_token.vue');
const WorkItemTypeToken = () =>
  import('~/vue_shared/components/filtered_search_bar/tokens/work_item_type_token.vue');

// Coalesces a burst of events into one refetch. For work item changes this also outlasts the
// backend's broadcast rate limit (50/minute per namespace), so a steady stream can't starve it.
const REALTIME_DEBOUNCE_MS = 500;

export default {
  issuableListTabs,
  WORK_ITEM_CREATE_SOURCES,
  CREATION_CONTEXT_LIST_ROUTE,
  VIEW_CONTEXT,
  VIEW_MODE_LIST,
  VIEW_MODE_BOARD,
  searchProjectsQuery,
  i18n: {
    boardFeedbackLinkText: s__('WorkItemPlanningView|Share feedback on the Board view'),
    tablePlaceholder: s__('WorkItemPlanningView|Table placeholder'),
  },
  BOARD_FEEDBACK_ISSUE_URL: 'https://gitlab.com/gitlab-org/gitlab/-/work_items/607858',
  name: 'PlanningView',
  components: {
    GlButton,
    GlAlert,
    GlIntersectionObserver,
    InfoBanner,
    SavedViewsNotFoundModal,
    SavedViewsLimitWarningModal,
    SavedViewsSelectors,
    ListActions,
    CreateWorkItemModal,
    FilteredSearchBar,
    WorkItemDisplaySettingsDrawer,
    EmptyStateWithAnyIssues,
    EmptyStateWithoutAnyIssues,
    EmptyStateWithAnyTickets,
    EmptyStateWithoutAnyTickets,
    NewResourceDropdown,
    NewSavedViewModal,
    IssuableTabs,
    ListView,
    BoardView,
    WorkItemDetailPanel,
  },
  mixins: [glFeatureFlagMixin(), InternalEvents.mixin(), GlToastMixin],
  inject: [
    'isIssueRepositioningDisabled',
    'groupId',
    'subscribedSavedViewLimit',
    'canCreateSavedView',
    'newWorkItemEmailAddress',
    'canReadCrmOrganization',
    'hasStatusFeature',
    'canReadCrmContact',
    'showNewWorkItem',
    'releasesPath',
    'hasBlockedIssuesFeature',
    'hasIssuableHealthStatusFeature',
    'hasIssueDateFilterFeature',
    'hasIssueWeightsFeature',
    'hasOkrsFeature',
    'hasCustomFieldsFeature',
    'canCreateWorkItem',
    'autocompleteAwardEmojisPath',
    'metadataLoading',
    'canAdminIssue',
    'canBulkAdminEpic',
    'isGroup',
    'isGroupIssuesList',
    'isServiceDeskSupported',
    'workItemType',
    'hasGroupBulkEditFeature',
    'hasEpicsFeature',
    'hasQualityManagementFeature',
    'hasProjects',
    'getWorkItemTypeConfiguration',
    'workItemTypesConfiguration',
  ],
  props: {
    rootPageFullPath: {
      type: String,
      required: true,
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
  },

  data() {
    const loggedIn = isLoggedIn();
    const isSavedViewRoute = this.$route.name === ROUTES.savedView;
    const persistedViewMode = !isSavedViewRoute && planningViewAllItemsFilters.value?.viewMode;
    return {
      namespaceId: null,
      viewMode: persistedViewMode || VIEW_MODE_LIST,
      activeItem: null,
      sortKey: CREATED_DESC,
      error: undefined,
      initialSortKey: CREATED_DESC,
      initialViewSortKey: null,
      initialViewMode: VIEW_MODE_LIST,
      filterTokens: [],
      workItemsCount: 0,
      hasWorkItems: false,
      pageParams: {},
      listPageInfo: {},
      state: STATUS_OPEN,
      pageSize: DEFAULT_PAGE_SIZE,
      savedView: null,
      lastTrackedSavedViewId: null,
      showSavedViewNotFoundModal: false,
      subscribeFromModal: false,
      subscribedSavedViews: [],
      localDisplaySettings: {},
      initialViewDisplaySettings: {},
      initialViewTokens: [],
      initialPreferences: null,
      displaySettings: {},
      // False until the displaySettings query has actually resolved (or failed), so we
      // don't mistake "not fetched yet" for a real, empty visibleGroups selection.
      preferencesLoaded: false,
      showBulkEditSidebar: false,
      checkedIssuableIds: [],
      isStickyHeaderVisible: false,
      hasStateToken: false,
      isNewViewModalVisible: false,
      namespaceName: null,
      isLoggedIn: loggedIn,
      isSortKeyInitialized: !loggedIn,
      currentWorkItemsCount: 0,
      currentWorkItemIds: [],
      isDisplayDrawerOpen: false,
      displayDrawerPage: DISPLAY_SETTINGS_PAGE_ROOT,
      drawerTopOffset: '0px',
      boardUpdatedItem: null,
    };
  },

  apollo: {
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
        return isEmpty(this.queryVariables) || this.metadataLoading;
      },
      error(error) {
        Sentry.captureException(error);
      },
    },

    hasWorkItems: {
      query: hasWorkItemsQuery,
      variables() {
        return {
          fullPath: this.rootPageFullPath,
          ...this.apiTypesArgument,
        };
      },
      update(data) {
        return data?.namespace?.workItems.nodes.length > 0 || false;
      },
      result({ data }) {
        const namespaceId = data.namespace?.id;
        this.namespaceId = namespaceId;
        this.subscribeToWorkItemChanges(namespaceId);
      },
      error(error) {
        this.error = s__('WorkItem|An error occurred while getting work item counts.');
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
      async result({ data }) {
        try {
          const savedView = data?.namespace?.savedViews?.nodes[0];
          const limit = data?.namespace?.subscribedSavedViewLimit;
          const count = data?.namespace?.currentSavedViews?.nodes.length;

          const isDisabledBoardView =
            savedView?.displaySettings?.viewMode === VIEW_MODE_BOARD &&
            !this.isPlanningViewBoardEnabled;
          const isDisabledTableView =
            savedView?.displaySettings?.viewMode === VIEW_MODE_TABLE &&
            !this.isPlanningViewTableEnabled;

          if (!savedView || isDisabledBoardView || isDisabledTableView) {
            this.handleSavedViewNotFound();
            return;
          }

          if (!savedView.subscribed) {
            await this.handleUnsubscribedSavedView(savedView, { count, limit });
            return;
          }

          this.trackSavedViewVisit();
          this.applySavedViewState(savedView);
        } catch (error) {
          Sentry.captureException(error);
        }
      },
      error(error) {
        Sentry.captureException(error);
      },
    },

    subscribedSavedViews: {
      query: getNamespaceSavedViewsQuery,
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
      error(e) {
        Sentry.captureException(e);
      },
    },

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
        if (!this.isSavedView) {
          if (!planningViewAllItemsFilters.value) {
            this.sortKey = sortKey;
            const persistedViewMode =
              data?.currentUser?.workItemPreferences?.displaySettings?.viewMode;
            const isPersistedBoardModeUnavailable =
              persistedViewMode === VIEW_MODE_BOARD && !this.isPlanningViewBoardEnabled;
            const isPersistedTableModeUnavailable =
              persistedViewMode === VIEW_MODE_TABLE && !this.isPlanningViewTableEnabled;
            if (
              persistedViewMode &&
              !isPersistedBoardModeUnavailable &&
              !isPersistedTableModeUnavailable
            ) {
              this.viewMode = persistedViewMode;
            }
            // Sync default sort to URL on fresh load so the URL always reflects current state.
            // Guard against overwriting existing params (e.g. sv_limit_id on redirect from saved view).
            if (!Object.keys(this.$route.query).length) {
              this.updateRouterQueryParams();
            }
            this.saveSessionFilters(this.filterTokens);
          }
        }
        this.isSortKeyInitialized = true;
        this.preferencesLoaded = true;
      },
      skip() {
        return !this.workItemTypeId || !this.isLoggedIn;
      },
      error(error) {
        this.isSortKeyInitialized = true;
        this.preferencesLoaded = true;
        this.error = __('An error occurred while getting work item user preference.');
        Sentry.captureException(error);
      },
    },
  },

  computed: {
    isPlanningViewBoardEnabled() {
      return Boolean(this.glFeatures.planningViewBoards);
    },
    isPlanningViewTableEnabled() {
      return Boolean(this.glFeatures.planningViewTable);
    },
    isBoardView() {
      return this.viewMode === VIEW_MODE_BOARD && this.isPlanningViewBoardEnabled;
    },
    isTableView() {
      return this.viewMode === VIEW_MODE_TABLE && this.isPlanningViewTableEnabled;
    },
    // `afterCursor` alone answers forward pagination. Backward pagination needs `hasPreviousPage`
    // too: paging next then back to page 1 leaves a real `beforeCursor` set (see
    // list_view.vue's handlePreviousPage), which would otherwise read as "not page 1".
    isViewingFirstPage() {
      return !this.pageParams.afterCursor && !this.listPageInfo.hasPreviousPage;
    },
    detailPanelViewContext() {
      return this.isBoardView ? VIEW_CONTEXT.drawerBoard : VIEW_CONTEXT.drawerList;
    },
    // The board can only be sorted manually, so it always shows Manual sort here,
    // no matter what sort the list is actually using. We only override the display,
    // not this.sortKey itself, so switching back to list view restores the user's real sort.
    effectiveSortKey() {
      return this.isBoardView ? RELATIVE_POSITION_ASC : this.sortKey;
    },
    manualSortOption() {
      return this.sortOptions.find(
        (option) => option.sortDirection?.ascending === RELATIVE_POSITION_ASC,
      );
    },
    boardSortOptions() {
      return this.manualSortOption ? [this.manualSortOption] : [];
    },
    drawerSortOptions() {
      return this.isBoardView ? this.boardSortOptions : this.sortOptions;
    },
    useRestApi() {
      return Boolean(this.glFeatures.workItemRestApiFrontendUsers);
    },
    workItemDetailPanelEnabled() {
      return this.displaySettings?.commonPreferences?.shouldOpenItemsInSidePanel ?? true;
    },
    isItemSelected() {
      return !isEmpty(this.activeItem);
    },
    activeWorkItemType() {
      const activeWorkItemTypeName =
        typeof this.activeItem?.workItemType === 'object'
          ? this.activeItem?.workItemType?.name
          : this.activeItem?.workItemType;
      return this.workItemType || activeWorkItemTypeName;
    },
    hasSearch() {
      return Boolean(this.searchQuery);
    },
    namespace() {
      return this.isGroup ? NAMESPACE_GROUP : NAMESPACE_PROJECT;
    },
    savedViewNotFound() {
      return this.isSavedView && !this.savedView;
    },
    isSubscribedToSavedView() {
      return this.isSavedView && this.savedView.subscribed;
    },
    shouldSkipDueToSavedViewState() {
      if (!this.isSavedView) {
        return false;
      }
      return this.savedViewNotFound || !this.isSubscribedToSavedView;
    },
    tabs() {
      if (this.withTabs) {
        return this.$options.issuableListTabs;
      }
      return [];
    },
    currentTabCount() {
      return this.workItemsCount;
    },
    preferencesChanged() {
      if (!this.initialPreferences) return false;

      return preferencesChanged({
        currentPreferences: this.namespacePreferences,
        baselinePreferences: this.isSavedView
          ? this.initialViewDisplaySettings?.namespacePreferences
          : this.initialPreferences,
      });
    },
    filtersChanged() {
      return filtersChanged({
        filterTokens: this.filterTokens,
        baselineTokens: this.isSavedView ? this.initialViewTokens : ALL_ITEMS_DEFAULT_FILTER_TOKENS,
      });
    },
    sortChanged() {
      return sortChanged({
        sortKey: this.sortKey,
        baselineSortKey: this.isSavedView ? this.initialViewSortKey : this.initialSortKey,
      });
    },
    viewModeChanged() {
      return viewModeChanged({
        viewMode: this.viewMode,
        baselineViewMode: this.initialViewMode,
      });
    },
    viewConfigChanged() {
      if (this.isSavedView) {
        return (
          this.filtersChanged || this.sortChanged || this.preferencesChanged || this.viewModeChanged
        );
      }
      return this.filtersChanged;
    },
    isSubscriptionLimitReached() {
      return (
        this.subscribedSavedViewLimit &&
        this.subscribedSavedViews.length >= this.subscribedSavedViewLimit
      );
    },
    shouldShowSaveView() {
      return this.canCreateSavedView && this.viewConfigChanged && this.isLoggedIn;
    },
    showSaveChanges() {
      return this.savedView?.userPermissions?.updateSavedView && this.viewConfigChanged;
    },
    isBulkEditDisabled() {
      return this.showBulkEditSidebar || this.currentWorkItemsCount === 0;
    },
    initialLoadWasFiltered() {
      return this.filterTokens.length > 0;
    },
    hasActiveFilters() {
      return !isEmpty(this.apiFilterParams);
    },
    workItemTotalStateCount() {
      if (this.workItemsCount === null) {
        return '';
      }
      return n__('WorkItem|%d item', 'WorkItem|%d items', formatNumber(this.workItemsCount));
    },
    allowBulkEditing() {
      if (this.isBoardView) {
        return false;
      }
      if (this.isEpicsList) {
        return this.canBulkAdminEpic;
      }
      if (!this.isGroup) {
        return this.canAdminIssue;
      }
      // Groups require EE bulk edit feature, or CE planning view with projects
      const hasCEBulkEdit = this.hasProjects && !this.hasEpicsFeature;
      return this.canAdminIssue && (this.hasGroupBulkEditFeature || hasCEBulkEdit);
    },
    urlFilterParams() {
      return convertToUrlParams(this.filterTokens, {
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
      });
    },
    defaultWorkItemTypes() {
      return this.workItemTypesConfiguration
        .filter((type) => type.isFilterableListView)
        .map((type) => type.id);
    },
    queryVariables() {
      const hasGroupFilter = Boolean(this.urlFilterParams.group_path);
      const isIidSearch = ISSUE_REFERENCE.test(this.searchQuery);
      return {
        fullPath: this.rootPageFullPath,
        sort: this.effectiveSortKey,
        state: this.state,
        ...this.apiFilterParams,
        ...this.apiTypesArgument,
        ...this.pageParams,
        iid: isIidSearch ? this.searchQuery.slice(1) : undefined,
        search: isIidSearch ? undefined : this.searchQuery,
        excludeProjects: hasGroupFilter || this.isEpicsList,
        includeDescendants: !hasGroupFilter,
        isGroup: this.isGroup,
        excludeGroupWorkItems: this.isGroupIssuesList,
        useWorkItemFeatures: Boolean(this.glFeatures.workItemFeaturesField),
      };
    },
    isSavedView() {
      return this.$route.name === ROUTES.savedView;
    },
    isEpicsList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_EPIC;
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
          order: 4,
          type: TOKEN_TYPE_ASSIGNEE,
          title: TOKEN_TITLE_ASSIGNEE,
          icon: 'user',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          fetchUsers: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
          defaultUsers: this.isLoggedIn ? OPTIONS_NONE_ANY_ME : OPTIONS_NONE_ANY,
          multiSelect: true,
        },
        {
          order: 5,
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
          fetchUsers: this.fetchUsers,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-author`,
          preloadedUsers,
          multiSelect: true,
        },
        {
          order: 3,
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
          order: 7,
          type: TOKEN_TYPE_MILESTONE,
          title: TOKEN_TITLE_MILESTONE,
          icon: 'milestone',
          token: MilestoneToken,
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-milestone`,
          shouldSkipSort: true,
          fullPath: this.rootPageFullPath,
          isProject: !this.isGroup,
          fetchMilestones: this.fetchMilestones,
        },
        {
          order: 16,
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
          order: 17,
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
          order: 11,
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
          order: 2,
          type: TOKEN_TYPE_TYPE,
          title: TOKEN_TITLE_TYPE,
          icon: 'work-item-issue',
          unique: true,
          token: WorkItemTypeToken,
          multiSelect: true,
          operators: OPERATORS_IS_NOT_OR,
          fullPath: this.rootPageFullPath,
        });
      }

      if (this.isLoggedIn) {
        tokens.push({
          order: 12,
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

        if (this.autocompleteAwardEmojisPath) {
          tokens.push({
            order: 14,
            type: TOKEN_TYPE_MY_REACTION,
            title: TOKEN_TITLE_MY_REACTION,
            icon: 'thumb-up',
            token: EmojiToken,
            unique: true,
            fetchEmojis: this.fetchEmojis,
            recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-my_reaction`,
          });
        }

        tokens.push({
          order: 15,
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

      tokens.push({
        order: 1,
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

      if (this.hasIssueDateFilterFeature) {
        tokens.push({
          order: 18,
          type: TOKEN_TYPE_CLOSED,
          title: TOKEN_TITLE_CLOSED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          order: 19,
          type: TOKEN_TYPE_CREATED,
          title: TOKEN_TITLE_CREATED,
          icon: 'history',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          order: 20,
          type: TOKEN_TYPE_DUE_DATE,
          title: TOKEN_TITLE_DUE_DATE,
          icon: 'calendar',
          unique: true,
          token: DateToken,
          operators: OPERATORS_AFTER_BEFORE,
        });

        tokens.push({
          order: 21,
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
          order: 22,
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
          order: 23,
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
        order: 9,
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

      tokens.sort((a, b) => a.order - b.order);

      return tokens;
    },
    workItemTypeId() {
      // We should not be using ENUM and change the mount of work item type lists
      // with id instead since that is immutable
      const workItemTypeName = this.workItemType || WORK_ITEM_TYPE_NAME_ISSUE;
      const typeIdByName = this.getWorkItemTypeConfiguration(workItemTypeName)?.id;
      if (typeIdByName) {
        return typeIdByName;
      }

      // A namespace can rename the Issue type. The name lookup then misses, but the
      // renamed type keeps the id of the system type it was converted from.
      if (workItemTypeName === WORK_ITEM_TYPE_NAME_ISSUE) {
        const issueTypeGid = convertToGraphQLId(TYPENAME_WORK_ITEMS_TYPE, 1);
        return this.workItemTypesConfiguration?.find((type) => type?.id === issueTypeGid)?.id || '';
      }

      return '';
    },
    displaySettingsSoT() {
      return this.isSavedView
        ? {
            ...this.localDisplaySettings,
            commonPreferences: this.displaySettings.commonPreferences,
          }
        : this.displaySettings;
    },
    namespacePreferences() {
      return this.displaySettingsSoT?.namespacePreferences || {};
    },
    displaySettingsToSave() {
      return { ...this.namespacePreferences, viewMode: this.viewMode };
    },
    collapsedGroups() {
      return this.namespacePreferences.collapsedGroups ?? [];
    },
    groupOrder() {
      return this.namespacePreferences.groupOrder ?? [];
    },
    visibleGroups() {
      return this.namespacePreferences.visibleGroups ?? null;
    },
    hiddenMetadataKeys() {
      return this.namespacePreferences.hiddenMetadataKeys ?? [];
    },
    savedViewId() {
      return convertToGraphQLId('WorkItems::SavedViews::SavedView', this.$route.params.view_id);
    },
    allIssuablesChecked() {
      return (
        this.currentWorkItemsCount > 0 &&
        this.checkedIssuableIds.length === this.currentWorkItemsCount
      );
    },
    isInfoBannerVisible() {
      return this.isServiceDeskList && this.isServiceDeskSupported && this.hasWorkItems;
    },
    csvExportQueryVariables() {
      return {
        ...this.apiFilterParams,
        ...this.apiTypesArgument,
        projectPath: this.rootPageFullPath,
        state: this.state,
        search: this.searchQuery,
      };
    },
    searchQuery() {
      return convertToSearchQuery(this.filterTokens);
    },
    apiFilterParams() {
      const params = convertToApiParams(this.filterTokens, {
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
      });
      if (params.types) {
        params.workItemTypeIds = convertNumberToGid(params.types);
        delete params.types;
      }
      if (params.not?.types) {
        params.not.workItemTypeIds = convertNumberToGid(params.not.types);
        delete params.not.types;
      }
      return params;
    },
    apiTypesArgument() {
      const singleWorkItemType = this.getWorkItemTypeConfiguration(this.workItemType)?.id;
      const field = 'workItemTypeIds';
      return {
        [field]: this.apiFilterParams[field] || singleWorkItemType || this.defaultWorkItemTypes,
      };
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
    preselectedWorkItemType() {
      return this.isEpicsList ? WORK_ITEM_TYPE_NAME_EPIC : WORK_ITEM_TYPE_NAME_ISSUE;
    },
    canExport() {
      return !this.isGroup && this.isLoggedIn && this.currentWorkItemsCount > 0;
    },
    newIssueDropdownQueryVariables() {
      return {
        fullPath: this.rootPageFullPath,
      };
    },
    showLimitWarningModal() {
      return Boolean(this.$route.query.sv_limit_id && !this.$route.query.sv_source_modal);
    },
    showProjectNewWorkItem() {
      // In CE, groups cannot enable create_work_items, so showNewWorkItem is always false (only enabled in EE).
      // However, we need to show the button for CE groups with projects (!hasEpicsFeature indicates CE).
      return (this.isGroup && this.hasProjects && !this.hasEpicsFeature) || this.showNewWorkItem;
    },
    showGroupNewWorkItem() {
      return this.isGroupIssuesList && this.hasProjects;
    },
    isServiceDeskList() {
      return this.workItemType === WORK_ITEM_TYPE_NAME_TICKET;
    },
    viewDraftData() {
      return {
        sortKey: this.sortKey,
        displaySettings: this.localDisplaySettings,
        viewMode: this.viewMode,
      };
    },
    draftStorageContext() {
      return { rootPageFullPath: this.rootPageFullPath, viewId: this.$route.params.view_id };
    },
  },

  watch: {
    $route(newValue, oldValue) {
      if (!newValue.query[DETAIL_VIEW_QUERY_PARAM_NAME]) {
        this.activeItem = null;
      }
      if (newValue.fullPath !== oldValue.fullPath && !this.isSavedView) {
        const paginationKeys = ['page_after', 'page_before', 'first_page_size', 'last_page_size'];
        const hasPaginationParams = paginationKeys.some(
          (key) => newValue.query[key] || oldValue.query[key],
        );

        let onlyPaginationChanged = false;
        if (hasPaginationParams) {
          const oldQueryWithoutPagination = { ...oldValue.query };
          const newQueryWithoutPagination = { ...newValue.query };

          paginationKeys.forEach((key) => {
            delete oldQueryWithoutPagination[key];
            delete newQueryWithoutPagination[key];
          });

          onlyPaginationChanged = isEqual(oldQueryWithoutPagination, newQueryWithoutPagination);
        }

        if (!onlyPaginationChanged) {
          this.updateData(getParameterByName(PARAM_SORT));

          if (Object.keys(newValue.query).length === 0) {
            this.addStateToken();
          }
        }
      }
      if (this.isSavedView) {
        this.restoreViewDraft();
      }
    },
    eeSearchTokens() {
      if (this.isSavedView && Boolean(this.savedView)) {
        this.applySavedViewState(this.savedView);
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
              visibleGroups: value.namespacePreferences?.visibleGroups ?? null,
            },
          };
        }
        if (isEmpty(this.localDisplaySettings) || !this.isSavedView) {
          this.localDisplaySettings = { ...value };
        }
      },
    },
    isDisplayDrawerOpen(isOpen) {
      // The drawer is fixed, we need to keep its top edge below the header rows (which scroll
      // in-flow, then hand off to the sticky filter bar) while it is open.
      if (isOpen) {
        this.updateDrawerTopOffset();
        this.bindDrawerOffsetListeners();
      } else {
        this.unbindDrawerOffsetListeners();
      }
    },
    isStickyHeaderVisible() {
      if (this.isDisplayDrawerOpen) {
        this.$nextTick(() => this.updateDrawerTopOffset());
      }
    },
    workItemTypesConfiguration(workItemTypesConfiguration) {
      // When workItemTypesConfiguration becomes available and isSortKeyInitialized is still false,
      // set it to true to prevent the loading indicator from showing indefinitely
      if (workItemTypesConfiguration?.length > 0 && !this.isSortKeyInitialized && this.isLoggedIn) {
        this.isSortKeyInitialized = true;
      }

      // TODO remove when we no longer need to convert old type[]=ISSUE params to new type[]=1 params
      // The types load async, so only filter when the conversion actually changed a token.
      // Filtering unconditionally re-renders the filtered-search bar as the types resolve,
      // which discards a token the user is in the middle of building.
      if (this.filterTokens.some((token) => token.type === TOKEN_TYPE_TYPE)) {
        const tokens = convertOldTypeTokenEnumToGid(this.filterTokens, workItemTypesConfiguration);
        if (!isEqual(tokens, this.filterTokens)) {
          this.handleFilter(tokens);
        }
      }
    },
    hasCustomFieldsFeature(hasCustomFieldsFeature) {
      // The flag loads async, so it's undefined when created() first parses the URL.
      // Re-parse once it resolves so custom-field filters aren't dropped, but only
      // when the URL actually carries a custom-field param. Re-parsing unconditionally
      // reassigns filterTokens and re-renders the filtered-search bar as the flag
      // resolves, which drops the other tokens' suggestions.
      if (!hasCustomFieldsFeature || this.isSavedView) {
        return;
      }

      const params = new URLSearchParams(window.location.search);
      const hasCustomFieldParam = Array.from(params.keys()).some((key) =>
        key.startsWith('custom-field['),
      );
      if (hasCustomFieldParam) {
        this.updateData(getParameterByName(PARAM_SORT));
      }
    },
  },

  mounted() {
    setPageFullWidth();

    if (this.$route.query.sv_not_found) {
      this.showSavedViewNotFoundModal = true;
    }

    document.addEventListener('actioncable:reconnected', this.debouncedRefetchAfterReconnect);
  },
  beforeDestroy() {
    setPageDefaultWidth();
    this.unbindDrawerOffsetListeners();
    this.debouncedProcessWorkItemChanges.cancel();
    document.removeEventListener('actioncable:reconnected', this.debouncedRefetchAfterReconnect);
    this.debouncedRefetchAfterReconnect.cancel();
    this.workItemChangesSubscription?.unsubscribe();
  },

  created() {
    if (this.isSavedView) {
      this.pageParams = getInitialPageParams(this.pageSize);
    } else {
      const hasUrlQuery = Object.keys(this.$route.query).length > 0;

      this.updateData(getParameterByName(PARAM_SORT));

      if (!hasUrlQuery) {
        this.addStateToken();
      }
    }
    this.autocompleteCache = new AutocompleteCache();
    this.releasesCache = [];
    this.areReleasesFetched = false;
    this.drawerOffsetFrameId = null;
    this.drawerScroller = null;
    // Anonymous users never fetch displaySettings (see its `skip`), so there's no
    // preferences query to wait on — the answer ("no persisted visibleGroups") is
    // already known.
    if (!this.isLoggedIn) {
      this.preferencesLoaded = true;
    }
    // The types are provided above the keyed router-view, so on a remount they are already
    // resolved and the watcher never fires. With no type id the preferences query stays
    // skipped, so nothing else would ever clear the loading state of the list or the board.
    if (this.isLoggedIn && this.workItemTypesConfiguration?.length > 0 && !this.workItemTypeId) {
      this.isSortKeyInitialized = true;
      this.preferencesLoaded = true;
    }
    this.pendingWorkItemChanges = new Map();
    this.workItemChangesSubscription = null;
    this.debouncedProcessWorkItemChanges = debounce(
      this.processWorkItemChanges,
      REALTIME_DEBOUNCE_MS,
    );
    this.debouncedRefetchAfterReconnect = debounce(
      this.refetchAfterReconnect,
      REALTIME_DEBOUNCE_MS,
    );
  },

  methods: {
    saveSessionFilters(tokens) {
      if (this.isSavedView) {
        setSavedViewSessionFilters(this.$route.params.view_id, tokens);
      } else {
        setPlanningViewAllItemsFilters({
          filterTokens: [...tokens],
          sortKey: this.sortKey,
          state: this.state,
          viewMode: this.viewMode,
        });
      }
    },
    handleToggleViewMode(newViewMode) {
      this.trackEvent('switch_view_mode_on_work_item_planning_view', { label: newViewMode });
      this.viewMode = newViewMode;
      if (this.isSavedView) {
        this.persistSavedViewDraft();
        return;
      }
      this.saveSessionFilters(this.filterTokens);
      this.persistNamespaceDisplaySettings({
        ...this.namespacePreferences,
        viewMode: newViewMode,
      });
    },
    handleSetActiveItem(item) {
      this.activeItem = item;
    },
    handleWorkItemsChanged({ count, ids }) {
      this.currentWorkItemsCount = count;
      this.currentWorkItemIds = ids;
    },
    handleNamespaceDataLoaded({ namespaceName, data }) {
      this.namespaceName = namespaceName;
      document.title = this.calculateDocumentTitle(data);
    },
    deleteItem() {
      this.activeItem = null;
      this.refetchItems({ refetchCounts: true });
    },
    handleWorkItemUpdated(workItem) {
      this.handleStatusChange(workItem);
      if (this.isBoardView) {
        this.boardUpdatedItem = workItem;
      }
    },
    handleStatusChange(workItem) {
      if (this.state === STATUS_ALL) {
        return;
      }

      // Work item state can be either 'OPEN' or 'CLOSED', this.state can be 'opened' or 'closed'
      if (!this.state.includes(workItem.state.toLowerCase())) {
        this.refetchItems({ refetchCounts: true });
      }
    },
    toggleStickyHeader(isVisible) {
      this.isStickyHeaderVisible = isVisible;
    },
    toggleDisplayDrawer() {
      this.displayDrawerPage = DISPLAY_SETTINGS_PAGE_ROOT;
      this.isDisplayDrawerOpen = !this.isDisplayDrawerOpen;
    },
    openGroupByDisplaySettings() {
      this.displayDrawerPage = DISPLAY_SETTINGS_PAGE_GROUP_BY;
      this.isDisplayDrawerOpen = true;
    },
    closeDisplayDrawer() {
      this.isDisplayDrawerOpen = false;
      this.displayDrawerPage = DISPLAY_SETTINGS_PAGE_ROOT;
    },
    updateDrawerTopOffset() {
      // Keep the drawer in its original position on mobile
      if (PanelBreakpointInstance.getBreakpointSize() === 'xs') {
        this.drawerTopOffset = '';
        return;
      }
      // Anchor the fixed drawer to the bottom of the search bar that is on screen (either sticky or not)
      const el = this.isStickyHeaderVisible
        ? this.$refs.stickyFilteredSearchBar?.$el
        : this.$refs.filteredSearchBar?.$el;
      if (!el) {
        return;
      }
      // While the sticky search bar slides in it has a transform applied, which skews
      // getBoundingClientRect and makes the drawer overlap it. `top` and offsetHeight are layout
      // values unaffected by the transform, so measure the resting bottom from those instead. The
      // sticky bar is fixed relative to `.panel-content` (same containing block as the drawer), so
      // its `top` is already panel-relative and needs no further adjustment.
      if (this.isStickyHeaderVisible) {
        const stickyEl = el.closest('.sticky-filter') || el;
        const stickyBottom =
          (parseFloat(getComputedStyle(stickyEl).top) || 0) + stickyEl.offsetHeight;
        this.drawerTopOffset = `${Math.max(Math.round(stickyBottom) + 8, 0)}px`;
        return;
      }
      const anchor = this.$refs.stateCountRow || el;
      // Need to measure drawer's position based on the `.panel-content`, not the whole viewport.
      // Here we subtract the difference so the drawer's top edge lines up with the
      // anchor's bottom regardless of the containing block.
      const containingBlock = anchor.closest('.panel-content');
      const offsetTop = containingBlock ? containingBlock.getBoundingClientRect().top : 0;
      const { bottom } = anchor.getBoundingClientRect();

      this.drawerTopOffset = `${Math.max(Math.round(bottom - offsetTop) + 8, 0)}px`;
    },
    scheduleDrawerOffsetUpdate() {
      if (this.drawerOffsetFrameId) {
        return;
      }
      this.drawerOffsetFrameId = window.requestAnimationFrame(() => {
        this.drawerOffsetFrameId = null;
        this.updateDrawerTopOffset();
      });
    },
    bindDrawerOffsetListeners() {
      window.addEventListener('resize', this.scheduleDrawerOffsetUpdate, { passive: true });
      PanelBreakpointInstance.addBreakpointListener(this.scheduleDrawerOffsetUpdate);
      this.drawerScroller = this.$refs.stateCountRow?.closest('.panel-content-inner');
      this.drawerScroller?.addEventListener('scroll', this.scheduleDrawerOffsetUpdate, {
        passive: true,
      });
    },
    unbindDrawerOffsetListeners() {
      window.removeEventListener('resize', this.scheduleDrawerOffsetUpdate);
      PanelBreakpointInstance.removeBreakpointListener(this.scheduleDrawerOffsetUpdate);
      this.drawerScroller?.removeEventListener('scroll', this.scheduleDrawerOffsetUpdate);
      this.drawerScroller = null;
      if (this.drawerOffsetFrameId) {
        window.cancelAnimationFrame(this.drawerOffsetFrameId);
        this.drawerOffsetFrameId = null;
      }
    },
    getFilterTokensFromSavedView(savedViewFilters) {
      const tokens = getSavedViewFilterTokens(savedViewFilters, {
        includeStateToken: true,
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
        convertTypeTokens: true,
      });
      const availableTokenTypes = this.searchTokens.map((token) => token.type);
      const filteredTokens = tokens.filter(
        (token) => availableTokenTypes.includes(token.type) || token.type === FILTERED_SEARCH_TERM,
      );
      return convertLegacyTypeFormat(filteredTokens, this.getWorkItemTypeConfiguration);
    },
    handleSavedViewNotFound() {
      this.$router.push({ name: ROUTES.index, query: { sv_not_found: true } });
    },
    async handleUnsubscribedSavedView(savedView, { count, limit }) {
      if (count >= limit) {
        this.$router.push({
          name: ROUTES.index,
          query: { sv_limit_id: savedView.id, sv_source_modal: this.subscribeFromModal },
        });
        return;
      }

      const success = await this.attemptSubscription(savedView);
      if (!success) {
        throw new Error(
          `Unable to subscribe to view with id ${this.savedViewId} in ${this.rootPageFullPath}`,
        );
      }

      this.$toast.show(s__('WorkItem|View added to your list.'));
      // simple way to just restart the flow once we're subscribed.
      this.$apollo.queries.savedView.refetch();
      this.$apollo.queries.subscribedSavedViews.refetch();
    },
    trackSavedViewVisit() {
      if (this.lastTrackedSavedViewId !== this.savedViewId) {
        this.lastTrackedSavedViewId = this.savedViewId;
        this.trackEvent('saved_view_view');
      }
    },
    applySavedViewState(savedView) {
      const draft = getSavedViewDraft(this.draftStorageContext);
      const tokens = this.getFilterTokensFromSavedView(savedView?.filters || {});

      this.initialViewTokens = tokens;
      const { initialViewSortKey, initialViewMode, initialViewDisplaySettings } =
        buildInitialViewState({
          savedView,
          commonPreferences: this.displaySettings.commonPreferences,
        });
      this.initialViewSortKey = initialViewSortKey;
      this.initialViewMode = initialViewMode;
      this.initialViewDisplaySettings = initialViewDisplaySettings;

      const sessionFilters = getSavedViewSessionFilters(this.$route.params.view_id);
      this.filterTokens = sessionFilters ?? tokens;
      this.updateState(this.filterTokens);

      if (draft) {
        this.restoreViewDraft();
      } else {
        this.sortKey = initialViewSortKey;
        this.localDisplaySettings = initialViewDisplaySettings;
        this.viewMode = initialViewMode;
      }

      this.updateDocumentTitle();
    },
    restoreViewDraft() {
      const draft = getSavedViewDraft(this.draftStorageContext);
      if (!draft) return;

      const isDraftBoardModeUnavailable =
        draft.viewMode === VIEW_MODE_BOARD && !this.isPlanningViewBoardEnabled;
      const isDraftTableModeUnavailable =
        draft.viewMode === VIEW_MODE_TABLE && !this.isPlanningViewTableEnabled;

      this.sortKey = draft.sortKey;
      this.localDisplaySettings = draft.displaySettings;
      // If the board itself were unavailable we'd already have been redirected to "not found"
      // earlier. So getting here with an unavailable board draft means the saved view is
      // actually a list view with some stale, invalid board draft data left over.
      this.viewMode =
        isDraftBoardModeUnavailable || isDraftTableModeUnavailable
          ? VIEW_MODE_LIST
          : draft.viewMode;
    },
    handleClickTab(state) {
      if (this.state === state) {
        return;
      }

      this.state = state;
      this.pageParams = getInitialPageParams(this.pageSize);

      this.updateRouterQueryParams();
    },
    navigateToAllItems() {
      let query;
      if (planningViewAllItemsFilters.value) {
        const { filterTokens, sortKey, state } = planningViewAllItemsFilters.value;
        const urlFilterParams = convertToUrlParams(filterTokens, {
          hasCustomFieldsFeature: this.hasCustomFieldsFeature,
        });
        query = {
          sort: urlSortParams[sortKey],
          state,
          ...urlFilterParams,
          first_page_size: DEFAULT_PAGE_SIZE,
        };
      }
      this.$router.push({ name: ROUTES.index, query }).catch((error) => {
        if (error.name !== 'NavigationDuplicated') {
          throw error;
        }
      });
    },
    updateDocumentTitle() {
      if (this.isSavedView && this.savedView?.name && this.namespaceName) {
        const middleCrumb = this.namespaceName;
        const savedViewName =
          this.isSavedView && this.savedView?.name?.trim() ? this.savedView.name.trim() : '';
        const prefix = savedViewName
          ? `${savedViewName} · ${s__('WorkItem|Work items')}`
          : s__('WorkItem|Work items');
        document.title = `${prefix} · ${middleCrumb} · GitLab`;
      }
    },
    async updateView() {
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
          displaySettings: this.displaySettingsToSave,
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
        clearSavedViewDraft(this.draftStorageContext);
      } catch (e) {
        Sentry.captureException(e);
        this.error = s__('WorkItem|Something went wrong while saving the view');
      }
    },
    async saveViewChanges() {
      if (this.savedView?.isPrivate) {
        await this.updateView();
        return;
      }

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
        await this.updateView();
      }
    },
    async resetToViewDefaults() {
      this.filterTokens = [...this.initialViewTokens];
      this.sortKey = this.initialViewSortKey;
      this.localDisplaySettings = this.initialViewDisplaySettings;
      this.viewMode = this.initialViewMode;
      clearSavedViewDraft(this.draftStorageContext);
    },
    addStateToken() {
      this.hasStateToken = this.checkIfStateTokenExists();
      if (!this.hasStateToken) {
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
    showIssueRepositioningMessage() {
      createAlert({
        message: s__(
          'WorkItems|Sort order rebalancing in progress. Reordering is temporarily disabled.',
        ),
        variant: VARIANT_INFO,
      });
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

      let tokens = getFilterTokens(window.location.search, {
        includeStateToken: !this.withTabs,
        hasCustomFieldsFeature: this.hasCustomFieldsFeature,
        convertTypeTokens: true,
      });
      tokens = groupMultiSelectFilterTokens(tokens, this.searchTokens);

      if (!this.hasStateToken && this.state === STATUS_ALL) {
        tokens = tokens.filter((filterToken) => filterToken.type !== TOKEN_TYPE_STATE);
      }

      if (!isEqual(tokens, this.filterTokens)) {
        this.filterTokens = tokens;
      }

      let afterCursor = getParameterByName(PARAM_PAGE_AFTER) ?? undefined;
      let beforeCursor = getParameterByName(PARAM_PAGE_BEFORE) ?? undefined;

      // REST keyset cursors include a `_kd` direction marker that GraphQL cursors omit.
      // When a bookmarked URL is opened under a different API mode than the one that
      // produced its cursor the cursor is unusable. Reset pagination to page 1.
      const afterCompatible = isCursorCompatibleWithApi(afterCursor, this.useRestApi);
      const beforeCompatible = isCursorCompatibleWithApi(beforeCursor, this.useRestApi);

      if (!afterCompatible || !beforeCompatible) {
        afterCursor = undefined;
        beforeCursor = undefined;
        updateHistory({
          url: removeParams([PARAM_PAGE_AFTER, PARAM_PAGE_BEFORE]),
          replace: true,
        });
      }

      const newPageParams = getInitialPageParams(
        this.pageSize,
        isPositiveInteger(firstPageSize) ? parseInt(firstPageSize, 10) : undefined,
        isPositiveInteger(lastPageSize) ? parseInt(lastPageSize, 10) : undefined,
        afterCursor,
        beforeCursor,
      );

      // Only update pageParams if they actually changed to avoid triggering duplicate queries
      const paramsEqual = isEqual(this.pageParams, newPageParams);
      if (!paramsEqual) {
        this.pageParams = newPageParams;
      }

      // Trigger pageSize UI component update based on URL changes
      this.pageSize = this.pageParams.firstPageSize || DEFAULT_PAGE_SIZE;
      this.sortKey = sortKey;
      this.state = state || STATUS_OPEN;
    },
    async fetchReleases(search) {
      await this.waitForMetadata();

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
    async fetchEmojis(search) {
      await this.waitForMetadata();

      return this.autocompleteCache.fetch({
        url: this.autocompleteAwardEmojisPath,
        cacheName: 'emojis',
        searchProperty: 'name',
        search,
      });
    },
    // Token suggestions are fetched using values from the metadata query (isGroup and the
    // autocomplete paths), so wait for it. Without this, a fetch can fire against the wrong
    // namespace type or an undefined path and come back empty, with no retry.
    waitForMetadata() {
      if (!this.metadataLoading) {
        return Promise.resolve();
      }

      return new Promise((resolve) => {
        const unwatch = this.$watch('metadataLoading', (loading) => {
          if (!loading) {
            unwatch();
            resolve();
          }
        });
      });
    },
    async fetchUsers(search) {
      await this.waitForMetadata();

      const { data } = await this.$apollo.query({
        query: usersAutocompleteQuery,
        variables: { fullPath: this.rootPageFullPath, search, isProject: !this.isGroup },
      });

      return data[this.namespace]?.autocompleteUsers;
    },
    async fetchMilestones(search) {
      await this.waitForMetadata();

      const { data } = await this.$apollo.query({
        query: searchMilestonesQuery,
        variables: { fullPath: this.rootPageFullPath, search, isProject: !this.isGroup },
      });

      return data[this.namespace]?.milestones?.nodes;
    },
    async fetchLabelsWithFetchPolicy(search, fetchPolicy = fetchPolicies.CACHE_FIRST) {
      await this.waitForMetadata();

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
    handleError(error, message) {
      Sentry.captureException(error);

      // if custom message is provided, use it
      if (message) this.error = message;
    },
    async attemptSubscription(view) {
      try {
        await subscribeToSavedView({ view, cache: this.$apollo, fullPath: this.rootPageFullPath });
        return true;
      } catch (e) {
        this.error = s__(
          'WorkItem|An error occurred while subscribing to the view. Please try again.',
        );
        return false;
      }
    },
    persistSavedViewDraft() {
      if (!this.viewConfigChanged) {
        clearSavedViewDraft(this.draftStorageContext);
        return;
      }

      saveSavedViewDraft(this.draftStorageContext, this.viewDraftData);
    },
    handleAllIssuablesCheckedInput(value) {
      if (value) {
        this.checkedIssuableIds = [...this.currentWorkItemIds];
      } else {
        this.checkedIssuableIds = [];
      }
    },
    async handleLocalDisplayPreferencesUpdate(newSettings) {
      // Merge incoming keys so independent settings (hidden metadata fields and
      // collapsed board columns) don't clobber each other on a saved view draft.
      this.localDisplaySettings = {
        ...this.localDisplaySettings,
        namespacePreferences: {
          ...this.localDisplaySettings.namespacePreferences,
          ...newSettings,
        },
      };
      this.persistSavedViewDraft();
    },
    handleToggleGroupCollapse(groupId) {
      const current = this.namespacePreferences.collapsedGroups ?? [];
      const collapsedGroups = current.includes(groupId)
        ? current.filter((id) => id !== groupId)
        : [...current, groupId];
      const newSettings = { ...this.namespacePreferences, collapsedGroups };

      if (this.isSavedView) {
        this.handleLocalDisplayPreferencesUpdate(newSettings);
        return;
      }

      this.persistNamespaceDisplaySettings(newSettings);
    },
    handleReorderGroups(groupOrder) {
      const newSettings = { ...this.namespacePreferences, groupOrder };

      if (this.isSavedView) {
        this.handleLocalDisplayPreferencesUpdate(newSettings);
        return;
      }

      this.persistNamespaceDisplaySettings(newSettings);
    },
    handleHideGroup(visibleGroups) {
      const newSettings = { ...this.namespacePreferences, visibleGroups };

      if (this.isSavedView) {
        this.handleLocalDisplayPreferencesUpdate(newSettings);
        return;
      }

      this.persistNamespaceDisplaySettings(newSettings);
    },
    async persistNamespaceDisplaySettings(displaySettings) {
      if (!this.isLoggedIn) {
        return;
      }

      try {
        await updateNamespaceDisplaySettings({
          apolloClient: this.$apollo,
          namespacePath: this.rootPageFullPath,
          workItemTypeId: this.workItemTypeId,
          isSavedView: this.isSavedView,
          sort: this.sortKey,
          displaySettings,
        });
      } catch (error) {
        createAlert({
          message: __('Something went wrong while saving the preference.'),
          captureError: true,
          error,
        });
      }
    },
    updateRouterQueryParams() {
      if (this.isSavedView) {
        return;
      }

      // Preserve the detail panel params
      // so navigating between pages or changing the page size does not
      // close an open detail panel.
      const query = {
        ...this.urlParams,
        [DETAIL_VIEW_QUERY_PARAM_NAME]:
          getParameterByName(DETAIL_VIEW_QUERY_PARAM_NAME, undefined, { preservePlus: true }) ??
          undefined,
        [DETAIL_VIEW_DESIGN_VERSION_PARAM_NAME]:
          getParameterByName(DETAIL_VIEW_DESIGN_VERSION_PARAM_NAME, undefined, {
            preservePlus: true,
          }) ?? undefined,
      };

      this.$router.push({ query }).catch((error) => {
        if (error.name !== 'NavigationDuplicated') {
          throw error;
        }
      });
    },
    handleFilter(tokens) {
      const previousQueryVariables = this.queryVariables;

      this.filterTokens = tokens;
      this.hasStateToken = this.checkIfStateTokenExists();
      this.updateState(tokens);
      this.pageParams = getInitialPageParams(this.pageSize);

      this.updateRouterQueryParams();
      this.saveSessionFilters(tokens);

      if (this.isSavedView) {
        this.persistSavedViewDraft();
      }

      // on-filter fires on every search submit (search icon / Enter). When the
      // variables change, Apollo re-runs the list query on its own. When they
      // don't, force a reload so the query still re-runs on every submit.
      if (isEqual(previousQueryVariables, this.queryVariables)) {
        this.refetchItems({ refetchCounts: true });
      }
    },
    handleSetPageParams(pageParams) {
      this.pageParams = pageParams;
      this.updateRouterQueryParams();
    },
    handleSort(sortKey) {
      if (this.effectiveSortKey === sortKey) {
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
      this.saveSessionFilters(this.filterTokens);
      this.persistSavedViewDraft();
    },
    async saveSortPreference(sortKey) {
      try {
        const { data } = await persistSortPreference({
          apolloClient: this.$apollo,
          namespace: this.rootPageFullPath,
          workItemTypeId: this.workItemTypeId,
          sort: sortKey,
        });
        if (data?.workItemUserPreferenceUpdate?.errors?.length) {
          throw new Error(data.workItemUserPreferenceUpdate.errors);
        }
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    updateState(tokens) {
      this.state =
        tokens.find((token) => token.type === TOKEN_TYPE_STATE)?.value.data || STATUS_ALL;
    },
    handleWorkItemCreated() {
      this.refetchItems({ refetchCounts: true });
    },
    handleBoardWorkItemCreated() {
      this.$apollo.queries.workItemsCount.refetch();
    },
    async refetchItems({ refetchCounts = false }) {
      if (refetchCounts) {
        this.$apollo.queries.workItemsCount.refetch();
        this.$apollo.queries.hasWorkItems.refetch();
      }
      this.handleEvictCache();
    },
    extractProjects(data) {
      return data?.group?.projects?.nodes;
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
    calculateDocumentTitle(data) {
      const middleCrumb = data.namespace.name;
      if (this.isServiceDeskList) {
        return `${__('Service Desk')} · ${middleCrumb} · GitLab`;
      }
      const savedViewName = this.isSavedView && this.savedView?.name?.trim();
      if (savedViewName) {
        return `${savedViewName} · ${s__('WorkItem|Work items')} · ${middleCrumb} · GitLab`;
      }
      if (this.isGroup && this.isEpicsList) {
        return `${__('Epics')} · ${middleCrumb} · GitLab`;
      }
      return `${s__('WorkItem|Work items')} · ${middleCrumb} · GitLab`;
    },
    handleRefetch(scope) {
      if (scope === 'counts') {
        this.$apollo.queries.workItemsCount.refetch();
      }
      if (scope === 'all') {
        this.$apollo.queries.hasWorkItems.refetch();
        this.$apollo.queries.workItemsCount.refetch();
        this.handleEvictCache();
      }
    },
    subscribeToWorkItemChanges(namespaceId) {
      if (
        this.workItemChangesSubscription ||
        !namespaceId ||
        !this.glFeatures.workItemsRealtime ||
        !this.isLoggedIn
      ) {
        return;
      }

      this.workItemChangesSubscription = this.$apollo
        .subscribe({
          query: namespaceWorkItemChangesSubscription,
          variables: { namespaceId },
        })
        .subscribe({
          next: ({ data }) => this.recordWorkItemChange(data?.namespaceWorkItemChanges),
          error: (error) => Sentry.captureException(error),
        });
    },
    // A reconnect doesn't replay what was missed while disconnected, so the list can look live
    // but be stale. Reload everything rather than working out what changed.
    refetchAfterReconnect() {
      if (!this.glFeatures.workItemsRealtime) {
        return;
      }

      this.refetchItems({ refetchCounts: true });
    },
    // Events arrive for every work item in the namespace and its descendants, so a bulk edit can
    // fire many changes at once — buffer them and process together instead of one at a time.
    recordWorkItemChange(change) {
      if (!change?.workItemId) {
        return;
      }

      const { workItemId, action } = change;
      this.pendingWorkItemChanges.set(
        workItemId,
        mergeWorkItemChangeAction(this.pendingWorkItemChanges.get(workItemId), action),
      );
      this.debouncedProcessWorkItemChanges();
    },
    async processWorkItemChanges() {
      try {
        const changes = new Map(this.pendingWorkItemChanges);
        this.pendingWorkItemChanges.clear();

        const { created, updated, deleted } = groupWorkItemChanges(changes);
        const { cache } = this.$apollo.provider.defaultClient;

        const visibleDeleted = deleted.filter((id) => isWorkItemCached(cache, id));
        const hasVisibleUpdate = updated.some((id) => isWorkItemCached(cache, id));
        // Boards don't show one page at a time — they join every page together, so a new item
        // could always end up visible there.
        const canShowNewItems = this.isBoardView || this.isViewingFirstPage;

        // Close the drawer before evicting, otherwise its query reads an incomplete work item.
        if (this.activeItem && visibleDeleted.includes(this.activeItem.id)) {
          this.activeItem = null;
          await this.$nextTick();
        }

        const needsListRefetch = hasVisibleUpdate || (created.length > 0 && canShowNewItems);

        if (needsListRefetch) {
          this.refetchItems({ refetchCounts: true });
          return;
        }

        if (visibleDeleted.length > 0) {
          visibleDeleted.forEach((id) => evictWorkItem(cache, id));
          cache.gc();
        }

        // A change we ignored can still move the counts, and the payload doesn't say which
        // fields changed, so counts always refresh. Using `refetchQueries` instead of a single
        // query's `.refetch()` also catches every board column's own count query.
        this.$apollo.provider.defaultClient.refetchQueries({
          include: [getWorkItemsCountOnlyQuery],
        });
        if (created.length > 0 || deleted.length > 0) {
          this.$apollo.queries.hasWorkItems.refetch();
        }
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    handleEvictCache() {
      evictNamespaceWorkItems(this.$apollo.provider.defaultClient.cache, this.namespaceId, {
        useRestApi: this.useRestApi,
      });
    },
  },
};
</script>

<template>
  <div class="planning-view">
    <saved-views-not-found-modal
      :show="showSavedViewNotFoundModal"
      data-testid="view-not-found-modal"
      @hide="showSavedViewNotFoundModal = false"
    />
    <saved-views-limit-warning-modal
      :show="showLimitWarningModal"
      :view-id="$route.query.sv_limit_id"
      :full-path="rootPageFullPath"
      data-testid="view-limit-warning-modal"
    />
    <info-banner v-if="isInfoBannerVisible" />
    <work-item-detail-panel
      v-if="workItemDetailPanelEnabled"
      :active-item="activeItem"
      :open="isItemSelected"
      :issuable-type="activeWorkItemType"
      :is-board="isBoardView"
      :view-context="detailPanelViewContext"
      click-outside-exclude-selector=".issuable-list"
      @close="activeItem = null"
      @add-child="refetchItems"
      @work-item-deleted="deleteItem"
      @work-item-updated="handleWorkItemUpdated"
    />
    <div>
      <template v-if="!isServiceDeskList">
        <div v-if="error" class="gl-mt-5">
          <gl-alert variant="danger" :dismissible="hasWorkItems" @dismiss="error = undefined">
            {{ error }}
          </gl-alert>
        </div>

        <issuable-tabs v-if="withTabs" :tabs="tabs" :current-tab="state" @click="handleClickTab">
          <template #nav-actions>
            <div class="gl-flex gl-justify-end gl-gap-3">
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
                @work-item-created="handleWorkItemCreated"
              />
              <new-resource-dropdown
                v-if="showGroupNewWorkItem"
                :query="$options.searchProjectsQuery"
                :query-variables="newIssueDropdownQueryVariables"
                :extract-projects="extractProjects"
                :group-id="groupId"
              />
              <list-actions
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
        </issuable-tabs>
        <saved-views-selectors
          v-else
          :selected-saved-view="savedView"
          :full-path="rootPageFullPath"
          :saved-views="subscribedSavedViews"
          :sort-key="sortKey"
          :filters="apiFilterParams"
          :display-settings="displaySettingsToSave"
          @navigate-to-all-items="navigateToAllItems"
          @reset-to-default-view="resetToDefaultView"
          @subscribe-from-modal="subscribeFromModal = true"
          @error="handleError"
        >
          <template #header-area>
            <list-actions
              :can-export="canExport"
              :show-work-item-by-email-button="showWorkItemByEmail"
              :work-item-count="workItemsCount"
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
              @work-item-created="handleWorkItemCreated"
            />
          </template>
        </saved-views-selectors>
      </template>
      <filtered-search-bar
        ref="filteredSearchBar"
        :namespace="rootPageFullPath"
        recent-searches-storage-key="issues"
        :search-input-placeholder="__('Search or filter results…')"
        :tokens="searchTokens"
        :initial-filter-value="filterTokens"
        :initial-sort-by="effectiveSortKey"
        sync-filter-and-sort
        :show-checkbox="showBulkEditSidebar"
        :checkbox-checked="allIssuablesChecked"
        show-friendly-text
        terms-as-tokens
        class="row-content-block gl-grow gl-border-t-0 @sm/panel:gl-flex"
        data-testid="issuable-search-container"
        @checked-input="handleAllIssuablesCheckedInput"
        @on-filter="handleFilter"
        @on-sort="handleSort"
      >
        <template #user-preference>
          <gl-button
            icon="preferences"
            :selected="isDisplayDrawerOpen"
            data-testid="display-settings-button"
            @click="toggleDisplayDrawer"
          >
            {{ __('Display') }}
          </gl-button>
        </template>
      </filtered-search-bar>
      <gl-intersection-observer
        @appear="toggleStickyHeader(false)"
        @disappear="toggleStickyHeader(true)"
      >
        <transition name="issuable-header-slide">
          <div
            v-if="isStickyHeaderVisible"
            class="sticky-filter gl-fixed gl-left-auto gl-right-auto gl-z-3 gl-hidden @sm/panel:gl-block"
          >
            <filtered-search-bar
              ref="stickyFilteredSearchBar"
              :namespace="rootPageFullPath"
              recent-searches-storage-key="issues"
              :search-input-placeholder="__('Search or filter results…')"
              :tokens="searchTokens"
              :initial-filter-value="filterTokens"
              :initial-sort-by="effectiveSortKey"
              sync-filter-and-sort
              :show-checkbox="showBulkEditSidebar"
              :checkbox-checked="allIssuablesChecked"
              show-friendly-text
              terms-as-tokens
              class="row-content-block gl-grow gl-border-t-0 @sm/panel:gl-flex"
              data-testid="issuable-sticky-search-container"
              @checked-input="handleAllIssuablesCheckedInput"
              @on-filter="handleFilter"
              @on-sort="handleSort"
            >
              <template #user-preference>
                <gl-button
                  icon="preferences"
                  :selected="isDisplayDrawerOpen"
                  data-testid="display-settings-button"
                  @click="toggleDisplayDrawer"
                >
                  {{ __('Display') }}
                </gl-button>
              </template>
            </filtered-search-bar>
          </div>
        </transition>
      </gl-intersection-observer>
    </div>
    <template v-if="!isServiceDeskList">
      <!-- state-count -->
      <div
        ref="stateCountRow"
        class="gl-border-b gl-flex gl-h-8 gl-flex-wrap gl-justify-between gl-gap-y-3 gl-py-3 sm:gl-flex-nowrap"
      >
        <div class="gl-flex gl-items-center gl-gap-3">
          <span data-testid="work-item-count" class="gl-mr-3">{{ workItemTotalStateCount }}</span>
          <gl-button
            v-if="allowBulkEditing"
            size="small"
            category="primary"
            variant="default"
            :disabled="isBulkEditDisabled"
            data-testid="bulk-edit-start-button"
            @click="showBulkEditSidebar = true"
          >
            {{ __('Bulk edit') }}
          </gl-button>
          <gl-button
            v-if="isPlanningViewBoardEnabled && viewMode === $options.VIEW_MODE_BOARD"
            size="small"
            variant="link"
            class="!gl-text-sm"
            :href="$options.BOARD_FEEDBACK_ISSUE_URL"
            target="_blank"
            rel="noopener noreferrer"
            data-testid="board-feedback-link"
          >
            {{ $options.i18n.boardFeedbackLinkText }}
          </gl-button>
        </div>

        <template v-if="!isSavedView">
          <gl-button
            v-if="shouldShowSaveView"
            size="small"
            category="primary"
            variant="default"
            data-testid="save-view-button"
            @click="isNewViewModalVisible = true"
          >
            {{ s__('WorkItem|Save view') }}
          </gl-button>
          <new-saved-view-modal
            v-model="isNewViewModalVisible"
            :full-path="rootPageFullPath"
            :title="s__('WorkItem|Save view')"
            :sort-key="sortKey"
            :filters="apiFilterParams"
            :display-settings="displaySettingsToSave"
            :show-subscription-limit-warning="isSubscriptionLimitReached"
            @hide="isNewViewModalVisible = false"
          />
        </template>
        <template v-else>
          <div v-if="viewConfigChanged" class="gl-flex">
            <gl-button
              v-if="isLoggedIn"
              size="small"
              category="tertiary"
              class="!gl-text-sm"
              variant="link"
              data-testid="reset-view-button"
              @click="resetToViewDefaults"
            >
              {{ s__('WorkItem|Reset to defaults') }}
            </gl-button>
            <template v-if="showSaveChanges">
              <div
                data-testid="save-changes-separator"
                class="gl-border-r gl-mx-4 gl-h-full gl-w-1 gl-border-r-subtle"
              ></div>
              <gl-button
                size="small"
                category="primary"
                variant="default"
                data-testid="update-view-button"
                @click="saveViewChanges"
              >
                {{ s__('WorkItem|Save changes') }}
              </gl-button>
            </template>
          </div>
        </template>
      </div>
    </template>
    <list-view
      v-if="viewMode !== $options.VIEW_MODE_BOARD && !isTableView"
      data-testid="list-view"
      :root-page-full-path="rootPageFullPath"
      :with-tabs="withTabs"
      :query-variables="queryVariables"
      :skip-query="shouldSkipDueToSavedViewState || metadataLoading"
      :work-items-count="workItemsCount"
      :has-work-items="hasWorkItems"
      :error="error"
      :initial-load-was-filtered="initialLoadWasFiltered"
      :show-bulk-edit-sidebar="showBulkEditSidebar"
      :checked-issuable-ids="checkedIssuableIds"
      :display-settings="displaySettingsSoT"
      :page-size="pageSize"
      :filter-tokens="filterTokens"
      :api-filter-params="apiFilterParams"
      :sort-key="sortKey"
      :is-sort-key-initialized="isSortKeyInitialized"
      :state="state"
      :active-item="activeItem"
      @toggle-bulk-edit-sidebar="($evt) => (showBulkEditSidebar = $evt)"
      @refetch-data="handleRefetch"
      @dismiss-alert="error = undefined"
      @set-error="($evt) => (error = $evt)"
      @update-tokens="($evt) => (filterTokens = $evt)"
      @set-checked-issuable-ids="($evt) => (checkedIssuableIds = $evt)"
      @set-page-params="handleSetPageParams"
      @page-info="($evt) => (listPageInfo = $evt)"
      @set-page-size="($evt) => (pageSize = $evt)"
      @select-item="handleSetActiveItem"
      @set-active-item="handleSetActiveItem"
      @work-items-changed="handleWorkItemsChanged"
      @namespace-data-loaded="handleNamespaceDataLoaded"
    >
      <template #list-empty-state>
        <template v-if="isServiceDeskList">
          <empty-state-with-any-tickets
            v-if="hasWorkItems"
            :has-search="hasSearch"
            :is-open-tab="false"
          />
          <empty-state-without-any-tickets v-else />
        </template>

        <empty-state-with-any-issues
          v-else-if="hasWorkItems"
          :has-search="hasSearch"
          :is-epic="isEpicsList"
          :with-tabs="false"
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
              @work-item-created="handleWorkItemCreated"
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
              @work-item-created="handleWorkItemCreated"
            />
            <new-resource-dropdown
              v-if="showGroupNewWorkItem"
              :query="$options.searchProjectsQuery"
              :query-variables="newIssueDropdownQueryVariables"
              :extract-projects="extractProjects"
              :group-id="groupId"
            />
          </template>
        </empty-state-without-any-issues>
      </template>
    </list-view>
    <board-view
      v-if="viewMode === $options.VIEW_MODE_BOARD && isPlanningViewBoardEnabled"
      :root-page-full-path="rootPageFullPath"
      :query-variables="queryVariables"
      :collapsed-groups="collapsedGroups"
      :group-order="groupOrder"
      :visible-groups="visibleGroups"
      :visible-groups-loaded="preferencesLoaded"
      :can-manage-columns="isLoggedIn"
      :hidden-metadata-keys="hiddenMetadataKeys"
      :active-item="activeItem"
      :detail-panel-enabled="workItemDetailPanelEnabled"
      :updated-work-item="boardUpdatedItem"
      :has-active-filters="hasActiveFilters"
      :preselected-work-item-type="preselectedWorkItemType"
      :can-create-work-item="showProjectNewWorkItem"
      @set-error="($evt) => (error = $evt)"
      @set-active-item="handleSetActiveItem"
      @toggle-collapse="handleToggleGroupCollapse"
      @reorder-groups="handleReorderGroups"
      @hide-group="handleHideGroup"
      @work-item-created="handleBoardWorkItemCreated"
      @open-group-by-settings="openGroupByDisplaySettings"
    />
    <div v-if="isTableView" class="gl-py-5" data-testid="table-view-placeholder">
      {{ $options.i18n.tablePlaceholder }}
    </div>
    <work-item-display-settings-drawer
      :open="isDisplayDrawerOpen"
      :page="displayDrawerPage"
      :header-height="drawerTopOffset"
      :view-mode="viewMode"
      :sort-options="drawerSortOptions"
      :sort-key="effectiveSortKey"
      :namespace-preferences="namespacePreferences"
      :common-preferences="displaySettings.commonPreferences"
      :full-path="rootPageFullPath"
      :is-service-desk-list="isServiceDeskList"
      :is-saved-view="isSavedView"
      :work-item-type-id="workItemTypeId"
      @close="closeDisplayDrawer"
      @page-change="displayDrawerPage = $event"
      @sort="handleSort"
      @update-settings="handleLocalDisplayPreferencesUpdate"
      @toggle-view-mode="handleToggleViewMode"
    />
  </div>
</template>
