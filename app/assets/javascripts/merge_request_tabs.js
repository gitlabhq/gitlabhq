/* eslint-disable class-methods-use-this */
import $ from 'jquery';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { createAlert } from '~/alert';
import { getCookie, isMetaClick, parseBoolean, scrollToElement } from '~/lib/utils/common_utils';
import { parseUrlPathname, visitUrl } from '~/lib/utils/url_utility';
import createEventHub from '~/helpers/event_hub_factory';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import BlobForkSuggestion from './blob/blob_fork_suggestion';
import Diff from './diff';
import { initDiffStatsDropdown } from './init_diff_stats_dropdown';
import axios from './lib/utils/axios_utils';

import { localTimeAgo } from './lib/utils/datetime_utility';
import { isInVueNoteablePage } from './lib/utils/dom_utils';
import { __, s__ } from './locale';
import syntaxHighlight from './syntax_highlight';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

// MergeRequestTabs
//
// Handles persisting and restoring the current tab selection and lazily-loading
// content on the MergeRequests#show page.
//
// ### Example Markup
//
//   <ul class="nav-links merge-request-tabs">
//     <li class="notes-tab active">
//       <a data-action="notes" data-target="#notes" data-toggle="tab" href="/foo/bar/-/merge_requests/1">
//         Discussion
//       </a>
//     </li>
//     <li class="commits-tab">
//       <a data-action="commits" data-target="#commits" data-toggle="tab" href="/foo/bar/-/merge_requests/1/commits">
//         Commits
//       </a>
//     </li>
//     <li class="diffs-tab">
//       <a data-action="diffs" data-target="#diffs" data-toggle="tab" href="/foo/bar/-/merge_requests/1/diffs">
//         Diffs
//       </a>
//     </li>
//   </ul>
//
//   <div class="tab-content">
//     <div class="notes tab-pane active" id="notes">
//       Notes Content
//     </div>
//     <div class="commits tab-pane" id="commits">
//       Commits Content
//     </div>
//     <div class="diffs tab-pane" id="diffs">
//       Diffs Content
//     </div>
//   </div>
//
//   <div class="mr-loading-status">
//     <div class="loading">
//       Loading Animation
//     </div>
//   </div>
//

// <100ms is typically indistinguishable from "instant" for users, but allows for re-rendering
const FAST_DELAY_FOR_RERENDER = 75;
// Store the `location` object, allowing for easier stubbing in tests
let { location } = window;

function scrollToContainer(container) {
  if (location.hash) {
    const $el = $(`${container} ${location.hash}:not(.match)`);

    if ($el.length) {
      scrollToElement($el[0]);
    }
  }
}

function mountPipelines() {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');
  const { mrWidgetData } = gl;
  const table = new Vue({
    components: {
      MergeRequestPipelinesTable: () => {
        return gon.features.mrPipelinesGraphql
          ? import('~/ci/merge_requests/components/pipelines_table_wrapper.vue')
          : import('~/commit/pipelines/legacy_pipelines_table_wrapper.vue');
      },
    },
    apolloProvider,
    provide: {
      artifactsEndpoint: pipelineTableViewEl.dataset.artifactsEndpoint,
      artifactsEndpointPlaceholder: pipelineTableViewEl.dataset.artifactsEndpointPlaceholder,
      targetProjectFullPath: mrWidgetData?.target_project_full_path || '',
      fullPath: pipelineTableViewEl.dataset.fullPath,
      graphqlPath: pipelineTableViewEl.dataset.graphqlPath,
      manualActionsLimit: 50,
      mergeRequestId: mrWidgetData ? mrWidgetData.iid : null,
      sourceProjectFullPath: mrWidgetData?.source_project_full_path || '',
      useFailedJobsWidget: true,
    },
    render(createElement) {
      return createElement('merge-request-pipelines-table', {
        props: {
          endpoint: pipelineTableViewEl.dataset.endpoint,
          emptyStateSvgPath: pipelineTableViewEl.dataset.emptyStateSvgPath,
          errorStateSvgPath: pipelineTableViewEl.dataset.errorStateSvgPath,
          canCreatePipelineInTargetProject: Boolean(
            mrWidgetData?.can_create_pipeline_in_target_project,
          ),
          sourceProjectFullPath: mrWidgetData?.source_project_full_path || '',
          targetProjectFullPath: mrWidgetData?.target_project_full_path || '',
          projectId: pipelineTableViewEl.dataset.projectId,
          mergeRequestId: mrWidgetData ? mrWidgetData.iid : null,
          isMergeRequestTable: true,
        },
      });
    },
  }).$mount();

  // $mount(el) replaces the el with the new rendered component. We need it in order to mount
  // it everytime this tab is clicked - https://vuejs.org/v2/api/#vm-mount
  pipelineTableViewEl.appendChild(table.$el);

  return table;
}

export function destroyPipelines(app) {
  if (app && app.$destroy) {
    app.$destroy();

    document.querySelector('#commit-pipeline-table-view').innerHTML = '';
  }

  return null;
}

function loadDiffs({ url, tabs }) {
  return axios.get(url).then(({ data }) => {
    const $container = $('#diffs');
    $container.html(data.html);
    initDiffStatsDropdown();

    localTimeAgo(document.querySelectorAll('#diffs .js-timeago'));
    syntaxHighlight($('#diffs .js-syntax-highlight'));

    tabs.createDiff();
    tabs.setHubToDiff();

    scrollToContainer('#diffs');

    $('.diff-file').each((i, el) => {
      new BlobForkSuggestion({
        openButtons: $(el).find('.js-edit-blob-link-fork-toggler'),
        forkButtons: $(el).find('.js-fork-suggestion-button'),
        cancelButtons: $(el).find('.js-cancel-fork-suggestion-button'),
        suggestionSections: $(el).find('.js-file-fork-suggestion-section'),
        actionTextPieces: $(el).find('.js-file-fork-suggestion-section-action'),
      }).init();
    });
  });
}

export function toggleLoader(state) {
  $('.mr-loading-status .loading').toggleClass('hide', !state);
}

export function getActionFromHref(pathName) {
  let action = pathName.match(/\/(\d+)\/(commits|diffs|pipelines|reports).*$/);

  if (action) {
    action = action.at(-1).replace(/(^\/|\.html)/g, '');
  } else {
    action = 'show';
  }

  return action;
}

export const pageBundles = {
  show: () => import(/* webpackPrefetch: true */ '~/mr_notes/mount_app'),
  diffs: () => import(/* webpackPrefetch: true */ '~/diffs'),
  reports: () => import('~/merge_requests/reports'),
};

export default class MergeRequestTabs {
  constructor({ action, setUrl, stubLocation } = {}) {
    const containers = document.querySelectorAll('.content-wrapper .container-fluid');
    this.contentWrapper = containers[containers.length - 1];
    this.mergeRequestTabs = document.querySelector('.merge-request-tabs-container');
    this.mergeRequestTabsAll =
      this.mergeRequestTabs && this.mergeRequestTabs.querySelectorAll
        ? this.mergeRequestTabs.querySelectorAll('.merge-request-tabs li')
        : null;
    this.mergeRequestTabPanes = document.querySelector('#diff-notes-app');
    this.mergeRequestTabPanesAll =
      this.mergeRequestTabPanes && this.mergeRequestTabPanes.querySelectorAll
        ? this.mergeRequestTabPanes.querySelectorAll('.tab-pane')
        : null;
    this.navbar = document.querySelector('.navbar-gitlab');
    this.peek = document.getElementById('js-peek');
    this.sidebar = document.querySelector('.js-right-sidebar');
    this.pageLayout = document.querySelector('.layout-page');
    this.expandSidebar = document.querySelectorAll('.js-expand-sidebar, .js-sidebar-toggle');
    this.paddingTop = 16;
    this.actionRegex = /\/(commits|diffs|pipelines|reports)(\.html)?\/?$/;

    this.scrollPositions = {};

    this.commitsTab = document.querySelector('.tab-content .commits.tab-pane');

    this.currentTab = null;
    this.diffsLoaded = false;
    this.diffsClass = null;
    this.commitsLoaded = false;
    this.isFixedLayoutPreferred = this.contentWrapper.classList.contains('container-limited');
    this.eventHub = createEventHub();
    this.loadedPages = { [action]: true };

    this.setUrl = setUrl !== undefined ? setUrl : true;
    this.setCurrentAction = this.setCurrentAction.bind(this);
    this.switchViewType = this.switchViewType.bind(this);
    this.tabShown = this.tabShown.bind(this);
    this.clickTab = this.clickTab.bind(this);

    if (stubLocation) {
      location = stubLocation;
    }

    this.bindEvents();
    this.mergeRequestTabs?.querySelector(`a[data-action='${action}']`)?.click?.();
  }

  bindEvents() {
    $('.merge-request-tabs a[data-toggle="tabvue"]').on('click', this.clickTab);
    window.addEventListener('popstate', (event) => {
      if (event?.state?.skipScrolling) return;
      const action = getActionFromHref(window.location.pathname);

      this.tabShown(action, location.href);
      this.eventHub.$emit('MergeRequestTabChange', action);
    });
    this.eventHub.$on('diff:switch-view-type', this.switchViewType);
  }

  // Used in tests
  unbindEvents() {
    $('.merge-request-tabs a[data-toggle="tabvue"]').off('click', this.clickTab);
    this.eventHub.$off('diff:switch-view-type', this.switchViewType);
  }

  storeScroll() {
    if (this.currentTab) {
      this.scrollPositions[this.currentTab] = document.documentElement.scrollTop;
    }
  }
  recallScroll(action) {
    const storedPosition = this.scrollPositions[action];
    if (storedPosition == null) return;

    setTimeout(() => {
      window.scrollTo({
        top: storedPosition > 0 ? storedPosition : 0,
        left: 0,
        behavior: 'auto',
      });
    }, FAST_DELAY_FOR_RERENDER);
  }

  clickTab(e) {
    if (e.currentTarget) {
      e.stopImmediatePropagation();
      e.preventDefault();

      this.storeScroll();

      const { action } = e.currentTarget.dataset || {};

      if (isMetaClick(e)) {
        const targetLink = e.currentTarget.getAttribute('href');
        visitUrl(targetLink, true);
      } else if (action) {
        const href = e.currentTarget.getAttribute('href');
        this.tabShown(action, href);
      }
    }
  }

  tabShown(action, href, shouldScroll = true) {
    toggleLoader(false);

    if (action !== this.currentTab && this.mergeRequestTabs) {
      this.currentTab = action;
      if (this.setUrl) {
        this.setCurrentAction(action);
      }

      if (this.mergeRequestTabPanesAll) {
        this.mergeRequestTabPanesAll.forEach((el) => {
          const tabPane = el;
          tabPane.style.display = 'none';
        });
      }

      if (this.mergeRequestTabsAll) {
        this.mergeRequestTabsAll.forEach((el) => {
          el.classList.remove('active');
        });
      }

      const tabPane = this.mergeRequestTabPanes.querySelector(`#${action}`);
      if (tabPane) tabPane.style.display = 'block';
      const tab = this.mergeRequestTabs.querySelector(`.${action}-tab`);
      if (tab) tab.classList.add('active');

      if (isInVueNoteablePage() && !this.loadedPages[action] && action in pageBundles) {
        toggleLoader(true);
        pageBundles[action]()
          .then(({ default: init }) => {
            toggleLoader(false);
            init();
            this.loadedPages[action] = true;
          })
          .catch(() => {
            toggleLoader(false);
            createAlert({ message: s__('MergeRequest|Failed to load the page') });
          });
      }

      this.expandSidebar?.forEach((el) => el.classList.toggle('!gl-hidden', action !== 'show'));

      if (action === 'commits') {
        if (!this.commitsLoaded) {
          this.loadCommits(href);
        }
        // this.hideSidebar();
        this.resetViewContainer();
        this.mergeRequestPipelinesTable = destroyPipelines(this.mergeRequestPipelinesTable);
      } else if (action === 'new') {
        this.expandView();
        this.resetViewContainer();
        this.mergeRequestPipelinesTable = destroyPipelines(this.mergeRequestPipelinesTable);
      } else if (this.isDiffAction(action)) {
        if (!isInVueNoteablePage()) {
          /*
            for pages where we have not yet converted to the new vue
            implementation we load the diff tab content the old way,
            inserting html rendered by the backend.

            in practice, this only occurs when comparing commits in
            the new merge request form page.
          */
          this.loadDiff({ endpoint: href, strip: true });
        }
        // this.hideSidebar();
        this.expandViewContainer();
        this.mergeRequestPipelinesTable = destroyPipelines(this.mergeRequestPipelinesTable);
        this.commitsTab.classList.remove('active');
      } else if (action === 'pipelines') {
        // this.hideSidebar();
        this.resetViewContainer();
        this.mountPipelinesView();
      } else if (action === 'reports') {
        this.resetViewContainer();
      } else {
        const notesTab = this.mergeRequestTabs.querySelector('.notes-tab');
        const notesPane = this.mergeRequestTabPanes.querySelector('#notes');
        if (notesPane) {
          notesPane.style.display = 'block';
        }
        if (notesTab) {
          notesTab.classList.add('active');
        }

        // this.showSidebar();
        this.resetViewContainer();
        this.mergeRequestPipelinesTable = destroyPipelines(this.mergeRequestPipelinesTable);
      }

      renderGFM(document.querySelector('.detail-page-description'));

      if (shouldScroll) this.recallScroll(action);
    } else if (action === this.currentAction) {
      // ContentTop is used to handle anything at the top of the page before the main content
      const mainContentContainer = document.querySelector('.content-wrapper');
      const tabContentContainer = document.querySelector('.tab-content');

      if (mainContentContainer && tabContentContainer) {
        const mainContentTop = mainContentContainer.getBoundingClientRect().top;
        const tabContentTop = tabContentContainer.getBoundingClientRect().top;

        // 51px is the height of the navbar buttons, e.g. `Discussion | Commits | Changes`
        const scrollDestination = tabContentTop - mainContentTop - 51;

        // scrollBehavior is only available in browsers that support scrollToOptions
        if ('scrollBehavior' in document.documentElement.style && shouldScroll) {
          window.scrollTo({
            top: scrollDestination,
            behavior: 'smooth',
          });
        } else {
          window.scrollTo(0, scrollDestination);
        }
      }
    }

    this.eventHub.$emit('MergeRequestTabChange', action);
  }

  // Replaces the current merge request-specific action in the URL with a new one
  //
  // If the action is "notes", the URL is reset to the standard
  // `MergeRequests#show` route.
  //
  // Examples:
  //
  //   location.pathname # => "/namespace/project/-/merge_requests/1"
  //   setCurrentAction('diffs')
  //   location.pathname # => "/namespace/project/-/merge_requests/1/diffs"
  //
  //   location.pathname # => "/namespace/project/-/merge_requests/1/diffs"
  //   setCurrentAction('show')
  //   location.pathname # => "/namespace/project/-/merge_requests/1"
  //
  //   location.pathname # => "/namespace/project/-/merge_requests/1/diffs"
  //   setCurrentAction('commits')
  //   location.pathname # => "/namespace/project/-/merge_requests/1/commits"
  //
  // Returns the new URL String
  setCurrentAction(action) {
    this.currentAction = action;

    const pathname = location.pathname.replace(/\/*$/, '');

    // Remove a trailing '/commits' '/diffs' '/pipelines'
    let newStatePathname = pathname.replace(this.actionRegex, '');

    // Append the new action if we're on a tab other than 'notes'
    if (
      this.currentAction !== 'show' &&
      this.currentAction !== 'new' &&
      this.currentAction !== 'reports'
    ) {
      newStatePathname += `/${this.currentAction}`;
    }

    // Ensure parameters and hash come along for the ride
    const newState = newStatePathname + location.search + location.hash;

    if (pathname !== newStatePathname) {
      window.history.pushState(
        {
          url: newState,
          action: this.currentAction,
        },
        document.title,
        newState,
      );
    } else {
      window.history.replaceState(
        {
          url: window.location.href,
          action,
        },
        document.title,
        window.location.href,
      );
    }

    return newState;
  }

  getCurrentAction() {
    return this.currentAction;
  }

  loadCommits(source, page = 1) {
    toggleLoader(true);

    axios
      .get(`${source}.json`, { params: { page, per_page: 100 } })
      .then(({ data: { html, count, next_page: nextPage } }) => {
        toggleLoader(false);

        document.querySelector('.js-commits-count').textContent = count;

        const commitsDiv = document.querySelector('div#commits');
        // eslint-disable-next-line no-unsanitized/property
        commitsDiv.innerHTML += html;
        localTimeAgo(commitsDiv.querySelectorAll('.js-timeago'));
        this.commitsLoaded = true;
        scrollToContainer('#commits');

        const loadMoreButton = document.querySelector('.js-load-more-commits');

        if (loadMoreButton) {
          loadMoreButton.addEventListener('click', (e) => {
            e.preventDefault();

            loadMoreButton.remove();
            this.loadCommits(source, loadMoreButton.dataset.nextPage);
          });
        }

        if (!nextPage) {
          return import('./add_context_commits_modal');
        }

        return null;
      })
      .then((m) => m?.default())
      .catch(() => {
        toggleLoader(false);
        createAlert({
          message: __('An error occurred while fetching this tab.'),
        });
      });
  }

  mountPipelinesView() {
    this.mergeRequestPipelinesTable = mountPipelines();
  }

  // load the diff tab content from the backend
  loadDiff({ endpoint, strip = true }) {
    if (this.diffsLoaded) {
      document.dispatchEvent(new CustomEvent('scroll'));
      return;
    }

    // We extract pathname for the current Changes tab anchor href
    // some pages like MergeRequestsController#new has query parameters on that anchor
    const diffUrl = strip ? `${parseUrlPathname(endpoint)}.json${location.search}` : endpoint;

    loadDiffs({
      url: diffUrl,
      tabs: this,
    })
      .then(() => {
        if (this.isDiffAction(this.currentAction)) {
          this.expandViewContainer();
        }

        this.diffsLoaded = true;
      })
      .catch(() => {
        createAlert({
          message: __('An error occurred while fetching this tab.'),
        });
      });
  }
  switchViewType({ source }) {
    this.diffsLoaded = false;

    this.loadDiff({ endpoint: source, strip: false });
  }
  createDiff() {
    if (!this.diffsClass) {
      this.diffsClass = new Diff({ mergeRequestEventHub: this.eventHub });
    }
  }
  setHubToDiff() {
    if (this.diffsClass) {
      this.diffsClass.mrHub = this.eventHub;
    }
  }

  diffViewType() {
    return $('.js-diff-view-buttons button.active').data('viewType');
  }

  isDiffAction(action) {
    return action === 'diffs' || action === 'new/diffs';
  }

  expandViewContainer() {
    this.contentWrapper.classList.remove('container-limited');
    this.contentWrapper.classList.remove('rd-page-container');
    this.contentWrapper.classList.add('diffs-container-limited');
  }

  resetViewContainer() {
    this.contentWrapper.classList.toggle('container-limited', this.isFixedLayoutPreferred);
    this.contentWrapper.classList.remove('diffs-container-limited');
  }

  // Expand the issuable sidebar unless the user explicitly collapsed it
  expandView() {
    if (parseBoolean(getCookie('collapsed_gutter'))) {
      return;
    }
    const $gutterBtn = $('.js-sidebar-toggle');
    const $collapseSvg = $gutterBtn.find('.js-sidebar-collapse');

    // Wait until listeners are set
    setTimeout(() => {
      // Only when sidebar is collapsed
      if ($collapseSvg.length && !$collapseSvg.hasClass('hidden')) {
        $gutterBtn.trigger('click', [true]);
      }
    }, 0);
  }

  hideSidebar() {
    if (!isInVueNoteablePage() || this.cachedPageLayoutClasses) return;

    this.cachedPageLayoutClasses = this.pageLayout.className;
    this.pageLayout.classList.remove('right-sidebar-collapsed', 'right-sidebar-expanded');
    this.sidebar.style.width = '0px';
  }

  showSidebar() {
    if (!isInVueNoteablePage() || !this.cachedPageLayoutClasses) return;

    this.pageLayout.className = this.cachedPageLayoutClasses;
    this.sidebar.style.width = '';
    delete this.cachedPageLayoutClasses;
  }
}
