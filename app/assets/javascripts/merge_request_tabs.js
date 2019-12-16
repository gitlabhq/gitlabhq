/* eslint-disable no-new, class-methods-use-this */

import $ from 'jquery';
import Vue from 'vue';
import Cookies from 'js-cookie';
import axios from './lib/utils/axios_utils';
import flash from './flash';
import BlobForkSuggestion from './blob/blob_fork_suggestion';
import initChangesDropdown from './init_changes_dropdown';
import bp from './breakpoints';
import {
  parseUrlPathname,
  handleLocationHash,
  isMetaClick,
  parseBoolean,
} from './lib/utils/common_utils';
import { isInVueNoteablePage } from './lib/utils/dom_utils';
import { getLocationHash } from './lib/utils/url_utility';
import Diff from './diff';
import { localTimeAgo } from './lib/utils/datetime_utility';
import syntaxHighlight from './syntax_highlight';
import Notes from './notes';
import { polyfillSticky } from './lib/utils/sticky';
import { __ } from './locale';

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
    this.eventHub = new Vue();

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
    this.initAffix();
  }

  bindEvents() {
    $('.merge-request-tabs a[data-toggle="tabvue"]').on('click', this.clickTab);
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
      }
    }
  }

  tabShown(action, href) {
    if (action !== this.currentTab && this.mergeRequestTabs) {
      this.currentTab = action;

      if (this.mergeRequestTabPanesAll) {
        this.mergeRequestTabPanesAll.forEach(el => {
          const tabPane = el;
          tabPane.style.display = 'none';
        });
      }

      if (this.mergeRequestTabsAll) {
        this.mergeRequestTabsAll.forEach(el => {
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
        if (bp.getBreakpointSize() !== 'lg') {
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
      if (this.setUrl) {
        this.setCurrentAction(action);
      }

      this.eventHub.$emit('MergeRequestTabChange', this.getCurrentAction());
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
  }

  scrollToElement(container) {
    if (location.hash) {
      const offset = 0 - ($('.navbar-gitlab').outerHeight() + $('.js-tabs-affix').outerHeight());
      const $el = $(`${container} ${location.hash}:not(.match)`);
      if ($el.length) {
        $.scrollTo($el[0], { offset });
      }
    }
  }

  // Replaces the current Merge Request-specific action in the URL with a new one
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

    // TODO: Consider refactoring in light of turbolinks removal.

    // Replace the current history state with the new one without breaking
    // Turbolinks' history.
    //
    // See https://github.com/rails/turbolinks/issues/363
    window.history.replaceState(
      {
        url: newState,
      },
      document.title,
      newState,
    );

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
        document.querySelector('div#commits').innerHTML = data.html;
        localTimeAgo($('.js-timeago', 'div#commits'));
        this.commitsLoaded = true;
        this.scrollToElement('#commits');

        this.toggleLoading(false);
      })
      .catch(() => {
        this.toggleLoading(false);
        flash(__('An error occurred while fetching this tab.'));
      });
  }

  mountPipelinesView() {
    const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');
    const { CommitPipelinesTable, mrWidgetData } = gl;

    this.commitPipelinesTable = new CommitPipelinesTable({
      propsData: {
        endpoint: pipelineTableViewEl.dataset.endpoint,
        helpPagePath: pipelineTableViewEl.dataset.helpPagePath,
        emptyStateSvgPath: pipelineTableViewEl.dataset.emptyStateSvgPath,
        errorStateSvgPath: pipelineTableViewEl.dataset.errorStateSvgPath,
        autoDevopsHelpPath: pipelineTableViewEl.dataset.helpAutoDevopsPath,
        canRunPipeline: true,
        projectId: pipelineTableViewEl.dataset.projectId,
        mergeRequestId: mrWidgetData ? mrWidgetData.iid : null,
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

        if (typeof gl.diffNotesCompileComponents !== 'undefined') {
          gl.diffNotesCompileComponents();
        }

        localTimeAgo($('.js-timeago', 'div#diffs'));
        syntaxHighlight($('#diffs .js-syntax-highlight'));

        if (this.isDiffAction(this.currentAction)) {
          this.expandViewContainer();
        }
        this.diffsLoaded = true;

        new Diff();
        this.scrollToElement('#diffs');

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
        flash(__('An error occurred while fetching this tab.'));
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
    const $gutterIcon = $('.js-sidebar-toggle i:visible');

    // Wait until listeners are set
    setTimeout(() => {
      // Only when sidebar is expanded
      if ($gutterIcon.is('.fa-angle-double-right')) {
        $gutterIcon.closest('a').trigger('click', [true]);
      }
    }, 0);
  }

  // Expand the issuable sidebar unless the user explicitly collapsed it
  expandView() {
    if (parseBoolean(Cookies.get('collapsed_gutter'))) {
      return;
    }
    const $gutterIcon = $('.js-sidebar-toggle i:visible');

    // Wait until listeners are set
    setTimeout(() => {
      // Only when sidebar is collapsed
      if ($gutterIcon.is('.fa-angle-double-left')) {
        $gutterIcon.closest('a').trigger('click', [true]);
      }
    }, 0);
  }

  initAffix() {
    const $tabs = $('.js-tabs-affix');

    // Screen space on small screens is usually very sparse
    // So we dont affix the tabs on these
    if (bp.getBreakpointSize() === 'xs' || !$tabs.length) return;

    /**
      If the browser does not support position sticky, it returns the position as static.
      If the browser does support sticky, then we allow the browser to handle it, if not
      then we default back to Bootstraps affix
    */
    if ($tabs.css('position') !== 'static') return;

    polyfillSticky($tabs);
  }
}
