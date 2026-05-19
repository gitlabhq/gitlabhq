<script>
import { GlButton, GlAlert, GlFilteredSearchToken, GlIntersectionObserver } from '@gitlab/ui';
import { isEmpty, isEqual, sortBy } from 'lodash-es';
import produce from 'immer';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import axios from '~/lib/utils/axios_utils';
import { s__, __, n__, formatNumber, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { InternalEvents } from '~/tracking';
import { createAlert, VARIANT_INFO } from '~/alert';
import { TYPENAME_USER, TYPENAME_NAMESPACE } from '~/graphql_shared/constants';
import { getParameterByName } from '~/lib/utils/url_utility';
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
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

import {
  FILTERED_SEARCH_TERM,
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

import searchLabelsQuery from '~/work_items/list/graphql/search_labels.query.graphql';
import getWorkItemsCountOnlyQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_count_only.query.graphql';
import hasWorkItemsQuery from '~/work_items/list/graphql/has_work_items.query.graphql';
import updateWorkItemListUserPreference from '~/work_items/graphql/update_work_item_list_user_preferences.mutation.graphql';
import getUserWorkItemsPreferences from '~/work_items/graphql/get_user_preferences.query.graphql';
import namespaceSavedViewQuery from '~/work_items/list/graphql/namespace_saved_view.query.graphql';
import getNamespaceSavedViewsQuery from '~/work_items/list/graphql/work_item_saved_views_namespace.query.graphql';

import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import IssuableTabs from '~/vue_shared/issuable/list/components/issuable_tabs.vue';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import ListView from 'ee_else_ce/work_items/list/list_view.vue';

import {
  convertLegacyTypeFormat,
  convertOldTypeTokenEnumToGid,
  convertNumberToGid,
  getSortOptions,
  getInitialPageParams,
  subscribeToSavedView,
  convertToApiParams,
  convertToUrlParams,
  deriveSortKey,
  getFilterTokens,
  groupMultiSelectFilterTokens,
  saveSavedView,
  getSavedViewFilterTokens,
  convertToSearchQuery,
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
  planningViewSavedViewFilterTokens,
  setPlanningViewAllItemsFilters,
  setPlanningViewSavedViewFilterTokens,
} from '~/work_items/pages/planning_view_state';

import searchProjectsQuery from '../list/graphql/search_projects.query.graphql';

import SavedViewsNotFoundModal from '../list/components/work_items_saved_views_not_found_modal.vue';
import SavedViewsLimitWarningModal from '../list/components/work_items_saved_views_limit_warning_modal.vue';
import SavedViewsSelectors from '../list/components/work_items_saved_views_selectors.vue';
import ListActions from '../list/components/work_item_list_actions.vue';
import CreateWorkItemModal from '../components/create_work_item_modal.vue';
import UserPreferences from '../list/components/work_item_user_preferences.vue';
import EmptyStateWithAnyIssues from '../list/components/empty_state_with_any_issues.vue';
import EmptyStateWithoutAnyIssues from '../list/components/empty_state_without_any_issues.vue';
import EmptyStateWithAnyTickets from '../list/components/empty_state_with_any_tickets.vue';
import EmptyStateWithoutAnyTickets from '../list/components/empty_state_without_any_tickets.vue';
import InfoBanner from '../list/components/info_banner.vue';
import NewSavedViewModal from '../list/components/work_items_new_saved_view_modal.vue';
import WorkItemsOnboardingModal from '../components/work_items_onboarding_modal/work_items_onboarding_modal.vue';
import WorkItemDetailPanel from '../components/work_item_detail_panel.vue';
import WorkItemDisplaySettingsDrawer from '../list/components/work_item_display_settings_drawer.vue';

import {
  WORK_ITEM_TYPE_NAME_TICKET,
  NAME_TO_ENUM_MAP,
  WORK_ITEM_TYPE_NAME_EPIC,
  WORK_ITEM_TYPE_NAME_ISSUE,
  ROUTES,
  WORK_ITEM_CREATE_SOURCES,
  CREATION_CONTEXT_LIST_ROUTE,
  DETAIL_VIEW_QUERY_PARAM_NAME,
  VIEW_CONTEXT,
} from '../constants';

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

export default {
  issuableListTabs,
  WORK_ITEM_CREATE_SOURCES,
  CREATION_CONTEXT_LIST_ROUTE,
  VIEW_CONTEXT,
  searchProjectsQuery,
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
    UserPreferences,
    WorkItemDisplaySettingsDrawer,
    EmptyStateWithAnyIssues,
    EmptyStateWithoutAnyIssues,
    EmptyStateWithAnyTickets,
    EmptyStateWithoutAnyTickets,
    NewResourceDropdown,
    NewSavedViewModal,
    IssuableTabs,
    ListView,
    WorkItemsOnboardingModal,
    UserCalloutDismisser,
    WorkItemDetailPanel,
  },
  mixins: [glFeatureFlagMixin(), InternalEvents.mixin()],
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
    return {
      namespaceId: null,
      activeItem: null,
      sortKey: CREATED_DESC,
      error: undefined,
      initialSortKey: CREATED_DESC,
      initialViewSortKey: null,
      filterTokens: [],
      workItemsCount: 0,
      hasWorkItems: false,
      pageParams: {},
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
        this.namespaceId = data.namespace?.id;
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
          if (!savedView) {
            this.$router.push({ name: ROUTES.index, query: { sv_not_found: true } });
            return;
          }
          if (!savedView.subscribed) {
            if (count >= limit) {
              this.$router.push({
                name: ROUTES.index,
                query: { sv_limit_id: savedView.id, sv_source_modal: this.subscribeFromModal },
              });
            } else {
              const success = await this.attemptSubscription(savedView);
              if (success) {
                this.$toast.show(s__('WorkItem|View added to your list.'));
                // simple way to just restart the flow once we're subscribed.
                this.$apollo.queries.savedView.refetch();
                this.$apollo.queries.subscribedSavedViews.refetch();
              } else {
                throw new Error(
                  `Unable to subscribe to view with id ${this.savedViewId} in ${this.rootPageFullPath}`,
                );
              }
            }
          } else {
            if (this.lastTrackedSavedViewId !== this.savedViewId) {
              this.lastTrackedSavedViewId = this.savedViewId;
              this.trackEvent('saved_view_view');
            }
            const draft = localStorage.getItem(this.savedViewDraftStorageKey);
            const tokens = this.getFilterTokensFromSavedView(savedView?.filters || {});
            this.initialViewTokens = tokens;
            this.initialViewSortKey = savedView?.sort;
            this.initialViewDisplaySettings = {
              commonPreferences: { ...this.displaySettings.commonPreferences },
              namespacePreferences: savedView.displaySettings,
            };

            const sessionFilters =
              planningViewSavedViewFilterTokens.value[this.$route.params.view_id];
            this.filterTokens = sessionFilters ?? tokens;
            this.updateState(this.filterTokens);

            if (draft) {
              this.restoreViewDraft();
            } else {
              this.sortKey = savedView?.sort;
              this.localDisplaySettings = {
                commonPreferences: { ...this.displaySettings.commonPreferences },
                namespacePreferences: savedView.displaySettings,
              };
            }

            this.updateDocumentTitle();
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
            // Sync default sort to URL on fresh load so the URL always reflects current state.
            // Guard against overwriting existing params (e.g. sv_limit_id on redirect from saved view).
            if (!Object.keys(this.$route.query).length) {
              this.updateRouterQueryParams();
            }
            this.saveSessionFilters(this.filterTokens);
          }
        }
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
  },

  computed: {
    isDisplaySettingsDrawerEnabled() {
      return Boolean(this.glFeatures.workItemListDisplaySettingsDrawer);
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
    filtersChanged() {
      const filteredTokens = this.filterTokens
        .filter((token) => {
          if (token.type === FILTERED_SEARCH_TERM) {
            return Boolean(token.value?.data);
          }

          return true;
        })
        .map(({ id, ...rest }) => {
          // Explicitly set undefined operator in filtered-search-term operator
          if (rest.type === FILTERED_SEARCH_TERM) {
            return {
              ...rest,
              value: { ...rest.value, operator: undefined },
            };
          }
          return rest;
        });

      const compareFilters = !this.isSavedView
        ? this.allItemsDefaultFilterTokens
        : this.initialViewTokens;

      // The sequence of the object can be changed so setting sortBy before comparing
      return !isEqual(sortBy(filteredTokens, ['type']), sortBy(compareFilters, ['type']));
    },
    sortChanged() {
      const compareSort = !this.isSavedView ? this.initialSortKey : this.initialViewSortKey;
      return this.sortKey !== compareSort;
    },
    viewConfigChanged() {
      if (this.isSavedView) {
        return this.filtersChanged || this.sortChanged || this.preferencesChanged;
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
    workItemTotalStateCount() {
      if (this.workItemsCount === null) {
        return '';
      }
      return n__('WorkItem|%d item', 'WorkItem|%d items', formatNumber(this.workItemsCount));
    },
    allowBulkEditing() {
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
        .map((type) =>
          this.glFeatures.workItemConfigurableTypes ? type.id : NAME_TO_ENUM_MAP[type.name],
        );
    },
    queryVariables() {
      const hasGroupFilter = Boolean(this.urlFilterParams.group_path);
      const isIidSearch = ISSUE_REFERENCE.test(this.searchQuery);
      return {
        fullPath: this.rootPageFullPath,
        sort: this.sortKey,
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
          recentSuggestionsStorageKey: `${this.rootPageFullPath}-issues-recent-tokens-assignee`,
          preloadedUsers,
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
      return this.getWorkItemTypeConfiguration(workItemTypeName)?.id || '';
    },
    displaySettingsSoT() {
      return this.isSavedView
        ? {
            ...this.localDisplaySettings,
            commonPreferences: this.displaySettings.commonPreferences,
          }
        : this.displaySettings;
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
        hasStatusFeature: this.hasStatusFeature,
      });
      if (this.glFeatures.workItemConfigurableTypes) {
        if (params.types) {
          params.workItemTypeIds = convertNumberToGid(params.types);
          delete params.types;
        }
        if (params.not?.types) {
          params.not.workItemTypeIds = convertNumberToGid(params.not.types);
          delete params.not.types;
        }
      }
      return params;
    },
    apiTypesArgument() {
      const singleWorkItemType = this.glFeatures.workItemConfigurableTypes
        ? this.getWorkItemTypeConfiguration(this.workItemType)?.id
        : NAME_TO_ENUM_MAP[this.workItemType];
      const field = this.glFeatures.workItemConfigurableTypes ? 'workItemTypeIds' : 'types';
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
      };
    },
    savedViewDraftStorageKey() {
      return `${this.rootPageFullPath}-saved-view-${this.$route.params.view_id}`;
    },
  },

  watch: {
    $route(newValue, oldValue) {
      if (!newValue.query[DETAIL_VIEW_QUERY_PARAM_NAME]) {
        this.activeItem = null;
      }
      if (newValue.fullPath !== oldValue.fullPath && !this.isSavedView) {
        this.updateData(getParameterByName(PARAM_SORT));

        if (Object.keys(newValue.query).length === 0) {
          this.addStateToken();
        }
      }
      if (this.isSavedView) {
        this.restoreViewDraft();
      }
    },
    eeSearchTokens() {
      if (this.isSavedView && Boolean(this.savedView)) {
        const tokens = this.getFilterTokensFromSavedView(this.savedView.filters);
        this.initialViewTokens = tokens;
        const sessionFilters = planningViewSavedViewFilterTokens.value[this.$route.params.view_id];
        this.filterTokens = sessionFilters ?? tokens;
        this.updateState(this.filterTokens);
        const draft = localStorage.getItem(this.savedViewDraftStorageKey);
        if (draft) {
          this.restoreViewDraft();
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
          this.localDisplaySettings = { ...value };
        }
      },
    },
    workItemTypesConfiguration(workItemTypesConfiguration) {
      // When workItemTypesConfiguration becomes available and isSortKeyInitialized is still false,
      // set it to true to prevent the loading indicator from showing indefinitely
      if (workItemTypesConfiguration?.length > 0 && !this.isSortKeyInitialized && this.isLoggedIn) {
        this.isSortKeyInitialized = true;
      }

      // TODO remove when we no longer need to convert old type[]=ISSUE params to new type[]=1 params
      if (
        this.glFeatures.workItemConfigurableTypes &&
        this.filterTokens.some((token) => token.type === TOKEN_TYPE_TYPE)
      ) {
        const tokens = convertOldTypeTokenEnumToGid(this.filterTokens, workItemTypesConfiguration);
        this.handleFilter(tokens);
      }
    },
  },

  mounted() {
    setPageFullWidth();

    if (this.$route.query.sv_not_found) {
      this.showSavedViewNotFoundModal = true;
    }
  },
  beforeDestroy() {
    setPageDefaultWidth();
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
  },

  methods: {
    saveSessionFilters(tokens) {
      if (this.isSavedView) {
        setPlanningViewSavedViewFilterTokens({
          ...planningViewSavedViewFilterTokens.value,
          [this.$route.params.view_id]: [...tokens],
        });
      } else {
        setPlanningViewAllItemsFilters({
          filterTokens: [...tokens],
          sortKey: this.sortKey,
          state: this.state,
        });
      }
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
      return this.glFeatures.workItemConfigurableTypes
        ? convertLegacyTypeFormat(filteredTokens, this.getWorkItemTypeConfiguration)
        : filteredTokens;
    },
    restoreViewDraft() {
      const draft = localStorage.getItem(this.savedViewDraftStorageKey);
      if (!draft) return;

      const parsedData = JSON.parse(draft);

      this.sortKey = parsedData.sortKey;
      this.localDisplaySettings = parsedData.displaySettings;
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
    clearLocalSavedViewsConfig() {
      localStorage.removeItem(this.savedViewDraftStorageKey);
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
      this.clearLocalSavedViewsConfig();
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
      this.pageSize = this.pageParams.firstPageSize || DEFAULT_PAGE_SIZE;
      this.sortKey = sortKey;
      this.state = state || STATUS_OPEN;
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
        this.clearLocalSavedViewsConfig();
        return;
      }

      localStorage.setItem(this.savedViewDraftStorageKey, JSON.stringify(this.viewDraftData));
    },
    handleAllIssuablesCheckedInput(value) {
      if (value) {
        this.checkedIssuableIds = [...this.currentWorkItemIds];
      } else {
        this.checkedIssuableIds = [];
      }
    },
    async handleLocalDisplayPreferencesUpdate(newSettings) {
      this.localDisplaySettings = {
        ...this.localDisplaySettings,
        namespacePreferences: {
          hiddenMetadataKeys: [...newSettings.hiddenMetadataKeys],
        },
      };
      this.persistSavedViewDraft();
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
    handleFilter(tokens) {
      this.filterTokens = tokens;
      this.hasStateToken = this.checkIfStateTokenExists();
      this.updateState(tokens);
      this.pageParams = getInitialPageParams(this.pageSize);

      this.updateRouterQueryParams();
      this.saveSessionFilters(tokens);

      if (this.isSavedView) {
        this.persistSavedViewDraft();
      }
    },
    handleSetPageParams(pageParams) {
      this.pageParams = pageParams;
      this.updateRouterQueryParams();
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
      this.saveSessionFilters(this.filterTokens);
      this.persistSavedViewDraft();
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
    updateState(tokens) {
      this.state =
        tokens.find((token) => token.type === TOKEN_TYPE_STATE)?.value.data || STATUS_ALL;
    },
    handleWorkItemCreated() {
      this.refetchItems({ refetchCounts: true });
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
    handleEvictCache() {
      const { cache } = this.$apollo.provider.defaultClient;
      cache.evict({
        id: cache.identify({ __typename: TYPENAME_NAMESPACE, id: this.namespaceId }),
        fieldName: 'workItems',
      });
      cache.gc();
    },
  },
};
</script>

<template>
  <div class="planning-view">
    <user-callout-dismisser feature-name="work_items_onboarding_modal">
      <template #default="{ dismiss, shouldShowCallout }">
        <work-items-onboarding-modal v-if="shouldShowCallout" @close="dismiss" />
      </template>
    </user-callout-dismisser>
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
      :view-context="$options.VIEW_CONTEXT.drawerList"
      click-outside-exclude-selector=".issuable-list"
      @close="activeItem = null"
      @add-child="refetchItems"
      @work-item-deleted="deleteItem"
      @work-item-updated="handleStatusChange"
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
          :display-settings="displaySettingsSoT.namespacePreferences"
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
      <!-- eslint-disable vue/v-on-event-hyphenation -->
      <filtered-search-bar
        :namespace="rootPageFullPath"
        recent-searches-storage-key="issues"
        :search-input-placeholder="__('Search or filter results…')"
        :tokens="searchTokens"
        :sort-options="sortOptions"
        :initial-filter-value="filterTokens"
        :initial-sort-by="sortKey"
        sync-filter-and-sort
        :show-checkbox="showBulkEditSidebar"
        :checkbox-checked="allIssuablesChecked"
        show-friendly-text
        terms-as-tokens
        class="row-content-block gl-grow gl-border-t-0 @sm/panel:gl-flex"
        data-testid="issuable-search-container"
        @checked-input="handleAllIssuablesCheckedInput"
        @onFilter="handleFilter"
        @onSort="handleSort"
      >
        <!-- eslint-enable vue/v-on-event-hyphenation -->
        <template #user-preference>
          <gl-button
            v-if="isDisplaySettingsDrawerEnabled"
            icon="preferences"
            data-testid="display-settings-button"
            @click="isDisplayDrawerOpen = true"
          >
            {{ __('Display') }}
          </gl-button>
          <user-preferences
            :namespace-preferences="displaySettingsSoT.namespacePreferences"
            :common-preferences="displaySettings.commonPreferences"
            :full-path="rootPageFullPath"
            :is-group="isGroup"
            :is-service-desk-list="isServiceDeskList"
            :work-item-type-id="workItemTypeId"
            :sort-key="sortKey"
            :prevent-auto-submit="isSavedView"
            @local-update="handleLocalDisplayPreferencesUpdate"
          />
        </template>
      </filtered-search-bar>
      <gl-intersection-observer
        @appear="toggleStickyHeader(false)"
        @disappear="toggleStickyHeader(true)"
      >
        <transition name="issuable-header-slide">
          <div
            v-if="isStickyHeaderVisible"
            class="sticky-filter gl-fixed gl-left-auto gl-right-auto gl-z-3 gl-hidden @md/panel:gl-block"
          >
            <!-- eslint-disable vue/v-on-event-hyphenation -->
            <filtered-search-bar
              :namespace="rootPageFullPath"
              recent-searches-storage-key="issues"
              :search-input-placeholder="__('Search or filter results…')"
              :tokens="searchTokens"
              :sort-options="sortOptions"
              :initial-filter-value="filterTokens"
              :initial-sort-by="sortKey"
              sync-filter-and-sort
              :show-checkbox="showBulkEditSidebar"
              :checkbox-checked="allIssuablesChecked"
              show-friendly-text
              terms-as-tokens
              class="row-content-block gl-grow gl-border-t-0 @sm/panel:gl-flex"
              data-testid="issuable-sticky-search-container"
              @checked-input="handleAllIssuablesCheckedInput"
              @onFilter="handleFilter"
              @onSort="handleSort"
            >
              <!-- eslint-enable vue/v-on-event-hyphenation -->
              <template #user-preference>
                <gl-button
                  v-if="isDisplaySettingsDrawerEnabled"
                  icon="preferences"
                  data-testid="display-settings-button"
                  @click="isDisplayDrawerOpen = true"
                >
                  {{ __('Display') }}
                </gl-button>
                <user-preferences
                  :namespace-preferences="displaySettingsSoT.namespacePreferences"
                  :common-preferences="displaySettings.commonPreferences"
                  :full-path="rootPageFullPath"
                  :is-group="isGroup"
                  :is-service-desk-list="isServiceDeskList"
                  :work-item-type-id="workItemTypeId"
                  :sort-key="sortKey"
                  :prevent-auto-submit="isSavedView"
                  @local-update="handleLocalDisplayPreferencesUpdate"
                />
              </template>
            </filtered-search-bar>
          </div>
        </transition>
      </gl-intersection-observer>
    </div>
    <template v-if="!isServiceDeskList">
      <!-- state-count -->
      <div class="gl-border-b gl-flex gl-flex-wrap gl-justify-between gl-gap-y-3 gl-py-3">
        <div class="gl-flex gl-flex-wrap gl-items-center gl-gap-3">
          <span data-testid="work-item-count">{{ workItemTotalStateCount }}</span>
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
            v-if="glFeatures.duoQuickActionWorkItemList"
            size="small"
            icon="tanuki-ai"
            data-testid="analyze-items-button"
          >
            {{ s__('WorkItem|Analyze items') }}
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
            :display-settings="displaySettings.namespacePreferences"
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
    <work-item-display-settings-drawer
      v-if="isDisplaySettingsDrawerEnabled"
      :open="isDisplayDrawerOpen"
      @close="isDisplayDrawerOpen = false"
    />
  </div>
</template>
