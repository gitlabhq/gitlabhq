import $ from 'jquery';
import { removeParams } from '~/lib/utils/url_utility';
import createGroupTree from '~/groups';
import {
  ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
  ACTIVE_TAB_SHARED,
  ACTIVE_TAB_ARCHIVED,
  CONTENT_LIST_CLASS,
  GROUPS_LIST_HOLDER_CLASS,
  GROUPS_FILTER_FORM_CLASS,
} from '~/groups/constants';
import UserTabs from '~/pages/users/user_tabs';
import GroupFilterableList from '~/groups/groups_filterable_list';

export default class GroupTabs extends UserTabs {
  constructor({ defaultAction = 'subgroups_and_projects', action, parentEl }) {
    super({ defaultAction, action, parentEl });
  }

  bindEvents() {
    this.$parentEl
      .off('shown.bs.tab', '.nav-links a[data-toggle="tab"]')
      .on('shown.bs.tab', '.nav-links a[data-toggle="tab"]', event => this.tabShown(event));
  }

  tabShown(event) {
    const $target = $(event.target);
    const action = $target.data('action') || $target.data('targetSection');
    const source = $target.attr('href') || $target.data('targetPath');

    document.querySelector(GROUPS_FILTER_FORM_CLASS).action = source;

    this.setTab(action);
    return this.setCurrentAction(source);
  }

  setTab(action) {
    const loadableActions = [
      ACTIVE_TAB_SUBGROUPS_AND_PROJECTS,
      ACTIVE_TAB_SHARED,
      ACTIVE_TAB_ARCHIVED,
    ];
    this.enableSearchBar(action);
    this.action = action;

    if (this.loaded[action]) {
      return;
    }

    if (loadableActions.includes(action)) {
      this.cleanFilterState();
      this.loadTab(action);
    }
  }

  loadTab(action) {
    const elId = `js-groups-${action}-tree`;
    const endpoint = this.getEndpoint(action);

    this.toggleLoading(true);

    createGroupTree(elId, endpoint, action);
    this.loaded[action] = true;

    this.toggleLoading(false);
  }

  getEndpoint(action) {
    const { endpointsDefault, endpointsShared } = this.$parentEl.data();
    let endpoint;

    switch (action) {
      case ACTIVE_TAB_ARCHIVED:
        endpoint = `${endpointsDefault}?archived=only`;
        break;
      case ACTIVE_TAB_SHARED:
        endpoint = endpointsShared;
        break;
      default:
        // ACTIVE_TAB_SUBGROUPS_AND_PROJECTS
        endpoint = endpointsDefault;
        break;
    }

    return endpoint;
  }

  enableSearchBar(action) {
    const containerEl = document.getElementById(action);
    const form = document.querySelector(GROUPS_FILTER_FORM_CLASS);
    const filter = form.querySelector('.js-groups-list-filter');
    const holder = containerEl.querySelector(GROUPS_LIST_HOLDER_CLASS);
    const dataEl = containerEl.querySelector(CONTENT_LIST_CLASS);
    const endpoint = this.getEndpoint(action);

    if (!dataEl) {
      return;
    }

    const { dataset } = dataEl;
    const opts = {
      form,
      filter,
      holder,
      filterEndpoint: endpoint || dataset.endpoint,
      pagePath: null,
      dropdownSel: '.js-group-filter-dropdown-wrap',
      filterInputField: 'filter',
      action,
    };

    if (!this.loaded[action]) {
      const filterableList = new GroupFilterableList(opts);
      filterableList.initSearch();
    }
  }

  cleanFilterState() {
    const values = Object.values(this.loaded);
    const loadedTabs = values.filter(e => e === true);

    if (!loadedTabs.length) {
      return;
    }

    const newState = removeParams(['page'], window.location.search);

    window.history.replaceState(
      {
        url: newState,
      },
      document.title,
      newState,
    );
  }
}
