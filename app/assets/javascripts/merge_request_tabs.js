/* eslint-disable no-new, class-methods-use-this */
import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import $ from 'jquery';
import Cookies from 'js-cookie';
import Vue from 'vue';
import createEventHub from '~/helpers/event_hub_factory';
import BlobForkSuggestion from './blob/blob_fork_suggestion';
import Diff from './diff';
import createFlash from './flash';
import initChangesDropdown from './init_changes_dropdown';
import axios from './lib/utils/axios_utils';
import {
  parseUrlPathname,
  handleLocationHash,
  isMetaClick,
  parseBoolean,
  scrollToElement,
} from './lib/utils/common_utils';
import { localTimeAgo } from './lib/utils/datetime_utility';
import { isInVueNoteablePage } from './lib/utils/dom_utils';
import { getLocationHash } from './lib/utils/url_utility';
import { __ } from './locale';
import Notes from './notes';
import syntaxHighlight from './syntax_highlight';

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

// Store the `location` object, allowing for easier stubbing in tests
let { location } = window;

export default class MergeRequestTabs {
  constructor({ action, setUrl, stubLocation } = {}) {
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
    const navbar = document.querySelector('.navbar-gitlab');
    const peek = document.getElementById('js-peek');
    const paddingTop = 16;

    this.commitsTab = document.querySelector('.tab-content .commits.tab-pane');

    this.currentTab = null;
    this.diffsLoaded = false;
    this.pipelinesLoaded = false;
    this.commitsLoaded = false;
    this.fixedLayoutPref = null;
    this.eventHub = createEventHub();

    this.setUrl = setUrl !== undefined ? setUrl : true;
    this.setCurrentAction = this.setCurrentAction.bind(this);
    this.tabShown = this.tabShown.bind(this);
    this.clickTab = this.clickTab.bind(this);
    this.stickyTop = navbar ? navbar.offsetHeight - paddingTop : 0;

    if (peek) {
      this.stickyTop += peek.offsetHeight;
    }

    if (this.mergeRequestTabs) {
      this.stickyTop += this.mergeRequestTabs.offsetHeight;
    }

    if (stubLocation) {
      location = stubLocation;
    }

    this.bindEvents();
    if (
      this.mergeRequestTabs &&
      this.mergeRequestTabs.querySelector(`a[data-action='${action}']`) &&
      this.mergeRequestTabs.querySelector(`a[data-action='${action}']`).click
    ) {
      this.mergeRequestTabs.querySelector(`a[data-action='${action}']`).click();
    }
  }

  bindEvents() {
    $('.merge-request-tabs a[data-toggle="tabvue"]').on('click', this.clickTab);
    window.addEventListener('popstate', (event) => {
      if (event.state && event.state.action) {
        this.tabShown(event.state.action, event.target.location);
        this.currentAction = event.state.action;
        this.eventHub.$emit('MergeRequestTabChange', this.getCurrentAction());
      }
    });
  }

  // Used in tests
  unbindEvents() {
    $('.merge-request-tabs a[data-toggle="tabvue"]').off('click', this.clickTab);
  }

  destroyPipelinesView() {
    if (this.commitPipelinesTable) {
      this.commitPipelinesTable.$destroy();
      this.commitPipelinesTable = null;

      document.querySelector('#commit-pipeline-table-view').innerHTML = '';
    }
  }

  clickTab(e) {
    if (e.currentTarget) {
      e.stopImmediatePropagation();
      e.preventDefault();

      const { action } = e.currentTarget.dataset || {};

      if (isMetaClick(e)) {
        const targetLink = e.currentTarget.getAttribute('href');
        window.open(targetLink, '_blank');
      } else if (action) {
        const href = e.currentTarget.getAttribute('href');
        this.tabShown(action, href);

        if (this.setUrl) {
          this.setCurrentAction(action);
        }
      }
    }
  }

  tabShown(action, href) {
    if (action !== this.currentTab && this.mergeRequestTabs) {
      this.currentTab = action;

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

      if (action === 'commits') {
        this.loadCommits(href);
        this.expandView();
        this.resetViewContainer();
        this.destroyPipelinesView();
      } else if (action === 'new') {
        this.expandView();
        this.resetViewContainer();
        this.destroyPipelinesView();
      } else if (this.isDiffAction(action)) {
        if (!isInVueNoteablePage()) {
          this.loadDiff(href);
        }
        if (bp.getBreakpointSize() !== 'xl') {
          this.shrinkView();
        }
        this.expandViewContainer();
        this.destroyPipelinesView();
        this.commitsTab.classList.remove('active');
      } else if (action === 'pipelines') {
        this.resetViewContainer();
        this.mountPipelinesView();
      } else {
        this.mergeRequestTabPanes.querySelector('#notes').style.display = 'block';
        this.mergeRequestTabs.querySelector('.notes-tab').classList.add('active');

        if (bp.getBreakpointSize() !== 'xs') {
          this.expandView();
        }
        this.resetViewContainer();
        this.destroyPipelinesView();
      }

      $('.detail-page-description').renderGFM();
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
        if ('scrollBehavior' in document.documentElement.style) {
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

  scrollToContainerElement(container) {
    if (location.hash) {
      const $el = $(`${container} ${location.hash}:not(.match)`);

      if ($el.length) {
        scrollToElement($el[0]);
      }
    }
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

    // Remove a trailing '/commits' '/diffs' '/pipelines'
    let newState = location.pathname.replace(/\/(commits|diffs|pipelines)(\.html)?\/?$/, '');

    // Append the new action if we're on a tab other than 'notes'
    if (this.currentAction !== 'show' && this.currentAction !== 'new') {
      newState += `/${this.currentAction}`;
    }

    // Ensure parameters and hash come along for the ride
    newState += location.search + location.hash;

    if (window.history.state && window.history.state.url && window.location.pathname !== newState) {
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

  loadCommits(source) {
    if (this.commitsLoaded) {
      return;
    }

    this.toggleLoading(true);

    axios
      .get(`${source}.json`)
      .then(({ data }) => {
        const commitsDiv = document.querySelector('div#commits');
        commitsDiv.innerHTML = data.html;
        localTimeAgo(commitsDiv.querySelectorAll('.js-timeago'));
        this.commitsLoaded = true;
        this.scrollToContainerElement('#commits');

        this.toggleLoading(false);

        return import('./add_context_commits_modal');
      })
      .then((m) => m.default())
      .catch(() => {
        this.toggleLoading(false);
        createFlash({
          message: __('An error occurred while fetching this tab.'),
        });
      });
  }

  mountPipelinesView() {
    const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');
    const { mrWidgetData } = gl;

    this.commitPipelinesTable = new Vue({
      components: {
        CommitPipelinesTable: () => import('~/commit/pipelines/pipelines_table.vue'),
      },
      provide: {
        artifactsEndpoint: pipelineTableViewEl.dataset.artifactsEndpoint,
        artifactsEndpointPlaceholder: pipelineTableViewEl.dataset.artifactsEndpointPlaceholder,
        targetProjectFullPath: mrWidgetData?.target_project_full_path || '',
      },
      render(createElement) {
        return createElement('commit-pipelines-table', {
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
          },
        });
      },
    }).$mount();

    // $mount(el) replaces the el with the new rendered component. We need it in order to mount
    // it everytime this tab is clicked - https://vuejs.org/v2/api/#vm-mount
    pipelineTableViewEl.appendChild(this.commitPipelinesTable.$el);
  }

  loadDiff(source) {
    if (this.diffsLoaded) {
      document.dispatchEvent(new CustomEvent('scroll'));
      return;
    }

    // We extract pathname for the current Changes tab anchor href
    // some pages like MergeRequestsController#new has query parameters on that anchor
    const urlPathname = parseUrlPathname(source);

    this.toggleLoading(true);

    axios
      .get(`${urlPathname}.json${location.search}`)
      .then(({ data }) => {
        const $container = $('#diffs');
        $container.html(data.html);

        initChangesDropdown(this.stickyTop);

        localTimeAgo(document.querySelectorAll('#diffs .js-timeago'));
        syntaxHighlight($('#diffs .js-syntax-highlight'));

        if (this.isDiffAction(this.currentAction)) {
          this.expandViewContainer();
        }
        this.diffsLoaded = true;

        new Diff();
        this.scrollToContainerElement('#diffs');

        $('.diff-file').each((i, el) => {
          new BlobForkSuggestion({
            openButtons: $(el).find('.js-edit-blob-link-fork-toggler'),
            forkButtons: $(el).find('.js-fork-suggestion-button'),
            cancelButtons: $(el).find('.js-cancel-fork-suggestion-button'),
            suggestionSections: $(el).find('.js-file-fork-suggestion-section'),
            actionTextPieces: $(el).find('.js-file-fork-suggestion-section-action'),
          }).init();
        });

        // Scroll any linked note into view
        // Similar to `toggler_behavior` in the discussion tab
        const hash = getLocationHash();
        const anchor = hash && $container.find(`.note[id="${hash}"]`);
        if (anchor && anchor.length > 0) {
          const notesContent = anchor.closest('.notes-content');
          const lineType = notesContent.hasClass('new') ? 'new' : 'old';
          Notes.instance.toggleDiffNote({
            target: anchor,
            lineType,
            forceShow: true,
          });
          anchor[0].scrollIntoView();
          handleLocationHash();
          // We have multiple elements on the page with `#note_xxx`
          // (discussion and diff tabs) and `:target` only applies to the first
          anchor.addClass('target');
        }

        this.toggleLoading(false);
      })
      .catch(() => {
        this.toggleLoading(false);
        createFlash({
          message: __('An error occurred while fetching this tab.'),
        });
      });
  }

  // Show or hide the loading spinner
  //
  // status - Boolean, true to show, false to hide
  toggleLoading(status) {
    $('.mr-loading-status .loading').toggleClass('hide', !status);
  }

  diffViewType() {
    return $('.js-diff-view-buttons button.active').data('viewType');
  }

  isDiffAction(action) {
    return action === 'diffs' || action === 'new/diffs';
  }

  expandViewContainer(removeLimited = true) {
    const $wrapper = $('.content-wrapper .container-fluid').not('.breadcrumbs');
    if (this.fixedLayoutPref === null) {
      this.fixedLayoutPref = $wrapper.hasClass('container-limited');
    }
    if (this.diffViewType() === 'parallel' || removeLimited) {
      $wrapper.removeClass('container-limited');
    } else {
      $wrapper.toggleClass('container-limited', this.fixedLayoutPref);
    }
  }

  resetViewContainer() {
    if (this.fixedLayoutPref !== null) {
      $('.content-wrapper .container-fluid').toggleClass('container-limited', this.fixedLayoutPref);
    }
  }

  shrinkView() {
    const $gutterBtn = $('.js-sidebar-toggle:visible');
    const $expandSvg = $gutterBtn.find('.js-sidebar-expand');

    // Wait until listeners are set
    setTimeout(() => {
      // Only when sidebar is expanded
      if ($expandSvg.length && $expandSvg.hasClass('hidden')) {
        $gutterBtn.trigger('click', [true]);
      }
    }, 0);
  }

  // Expand the issuable sidebar unless the user explicitly collapsed it
  expandView() {
    if (parseBoolean(Cookies.get('collapsed_gutter'))) {
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
}
