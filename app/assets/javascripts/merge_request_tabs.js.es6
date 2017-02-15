/* eslint-disable no-new, class-methods-use-this */
/* global Breakpoints */
/* global Cookies */
/* global Flash */

require('./breakpoints');
window.Cookies = require('vendor/js.cookie');
require('./flash');

/* eslint-disable max-len */
// MergeRequestTabs
//
// Handles persisting and restoring the current tab selection and lazily-loading
// content on the MergeRequests#show page.
//
// ### Example Markup
//
//   <ul class="nav-links merge-request-tabs">
//     <li class="notes-tab active">
//       <a data-action="notes" data-target="#notes" data-toggle="tab" href="/foo/bar/merge_requests/1">
//         Discussion
//       </a>
//     </li>
//     <li class="commits-tab">
//       <a data-action="commits" data-target="#commits" data-toggle="tab" href="/foo/bar/merge_requests/1/commits">
//         Commits
//       </a>
//     </li>
//     <li class="diffs-tab">
//       <a data-action="diffs" data-target="#diffs" data-toggle="tab" href="/foo/bar/merge_requests/1/diffs">
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
/* eslint-enable max-len */

(() => {
  // Store the `location` object, allowing for easier stubbing in tests
  let location = window.location;

  class MergeRequestTabs {

    constructor({ action, setUrl, stubLocation } = {}) {
      this.diffsLoaded = false;
      this.pipelinesLoaded = false;
      this.commitsLoaded = false;
      this.fixedLayoutPref = null;

      this.setUrl = setUrl !== undefined ? setUrl : true;
      this.setCurrentAction = this.setCurrentAction.bind(this);
      this.tabShown = this.tabShown.bind(this);
      this.showTab = this.showTab.bind(this);

      if (stubLocation) {
        location = stubLocation;
      }

      this.bindEvents();
      this.activateTab(action);
      this.initAffix();
    }

    bindEvents() {
      $(document)
        .on('shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', this.tabShown)
        .on('click', '.js-show-tab', this.showTab);

      $('.merge-request-tabs a[data-toggle="tab"]')
        .on('click', this.clickTab);
    }

    unbindEvents() {
      $(document)
        .off('shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', this.tabShown)
        .off('click', '.js-show-tab', this.showTab);

      $('.merge-request-tabs a[data-toggle="tab"]')
        .off('click', this.clickTab);
    }

    showTab(e) {
      e.preventDefault();
      this.activateTab($(e.target).data('action'));
    }

    clickTab(e) {
      if (e.currentTarget && gl.utils.isMetaClick(e)) {
        const targetLink = e.currentTarget.getAttribute('href');
        e.stopImmediatePropagation();
        e.preventDefault();
        window.open(targetLink, '_blank');
      }
    }

    tabShown(e) {
      const $target = $(e.target);
      const action = $target.data('action');

      if (action === 'commits') {
        this.loadCommits($target.attr('href'));
        this.expandView();
        this.resetViewContainer();
      } else if (this.isDiffAction(action)) {
        this.loadDiff($target.attr('href'));
        if (Breakpoints.get().getBreakpointSize() !== 'lg') {
          this.shrinkView();
        }
        if (this.diffViewType() === 'parallel') {
          this.expandViewContainer();
        }
        const navBarHeight = $('.navbar-gitlab').outerHeight();
        $.scrollTo('.merge-request-details .merge-request-tabs', {
          offset: -navBarHeight,
        });
      } else if (action === 'pipelines') {
        if (this.pipelinesLoaded) {
          return;
        }
        const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');
        gl.commits.pipelines.PipelinesTableBundle.$mount(pipelineTableViewEl);
        this.pipelinesLoaded = true;
      } else {
        this.expandView();
        this.resetViewContainer();
      }
      if (this.setUrl) {
        this.setCurrentAction(action);
      }
    }

    scrollToElement(container) {
      if (location.hash) {
        const offset = 0 - (
          $('.navbar-gitlab').outerHeight() +
          $('.layout-nav').outerHeight() +
          $('.js-tabs-affix').outerHeight()
        );
        const $el = $(`${container} ${location.hash}:not(.match)`);
        if ($el.length) {
          $.scrollTo($el[0], { offset });
        }
      }
    }

    // Activate a tab based on the current action
    activateTab(action) {
      const activate = action === 'show' ? 'notes' : action;
      // important note: the .tab('show') method triggers 'shown.bs.tab' event itself
      $(`.merge-request-tabs a[data-action='${activate}']`).tab('show');
    }

    // Replaces the current Merge Request-specific action in the URL with a new one
    //
    // If the action is "notes", the URL is reset to the standard
    // `MergeRequests#show` route.
    //
    // Examples:
    //
    //   location.pathname # => "/namespace/project/merge_requests/1"
    //   setCurrentAction('diffs')
    //   location.pathname # => "/namespace/project/merge_requests/1/diffs"
    //
    //   location.pathname # => "/namespace/project/merge_requests/1/diffs"
    //   setCurrentAction('notes')
    //   location.pathname # => "/namespace/project/merge_requests/1"
    //
    //   location.pathname # => "/namespace/project/merge_requests/1/diffs"
    //   setCurrentAction('commits')
    //   location.pathname # => "/namespace/project/merge_requests/1/commits"
    //
    // Returns the new URL String
    setCurrentAction(action) {
      this.currentAction = action === 'show' ? 'notes' : action;

      // Remove a trailing '/commits' '/diffs' '/pipelines' '/new' '/new/diffs'
      let newState = location.pathname.replace(/\/(commits|diffs|pipelines|new|new\/diffs)(\.html)?\/?$/, '');

      // Append the new action if we're on a tab other than 'notes'
      if (this.currentAction !== 'notes') {
        newState += `/${this.currentAction}`;
      }

      // Ensure parameters and hash come along for the ride
      newState += location.search + location.hash;

      // TODO: Consider refactoring in light of turbolinks removal.

      // Replace the current history state with the new one without breaking
      // Turbolinks' history.
      //
      // See https://github.com/rails/turbolinks/issues/363
      window.history.replaceState({
        url: newState,
      }, document.title, newState);

      return newState;
    }

    loadCommits(source) {
      if (this.commitsLoaded) {
        return;
      }
      this.ajaxGet({
        url: `${source}.json`,
        success: (data) => {
          document.querySelector('div#commits').innerHTML = data.html;
          gl.utils.localTimeAgo($('.js-timeago', 'div#commits'));
          this.commitsLoaded = true;
          this.scrollToElement('#commits');
        },
      });
    }

    loadDiff(source) {
      if (this.diffsLoaded) {
        return;
      }

      // We extract pathname for the current Changes tab anchor href
      // some pages like MergeRequestsController#new has query parameters on that anchor
      const urlPathname = gl.utils.parseUrlPathname(source);

      this.ajaxGet({
        url: `${urlPathname}.json${location.search}`,
        success: (data) => {
          $('#diffs').html(data.html);

          if (typeof gl.diffNotesCompileComponents !== 'undefined') {
            gl.diffNotesCompileComponents();
          }

          gl.utils.localTimeAgo($('.js-timeago', 'div#diffs'));
          $('#diffs .js-syntax-highlight').syntaxHighlight();

          if (this.diffViewType() === 'parallel' && this.isDiffAction(this.currentAction)) {
            this.expandViewContainer();
          }
          this.diffsLoaded = true;

          new gl.Diff();
          this.scrollToElement('#diffs');
        },
      });
    }

    // Show or hide the loading spinner
    //
    // status - Boolean, true to show, false to hide
    toggleLoading(status) {
      $('.mr-loading-status .loading').toggle(status);
    }

    ajaxGet(options) {
      const defaults = {
        beforeSend: () => this.toggleLoading(true),
        error: () => new Flash('An error occurred while fetching this tab.', 'alert'),
        complete: () => this.toggleLoading(false),
        dataType: 'json',
        type: 'GET',
      };
      $.ajax($.extend({}, defaults, options));
    }

    diffViewType() {
      return $('.inline-parallel-buttons a.active').data('view-type');
    }

    isDiffAction(action) {
      return action === 'diffs' || action === 'new/diffs';
    }

    expandViewContainer() {
      const $wrapper = $('.content-wrapper .container-fluid');
      if (this.fixedLayoutPref === null) {
        this.fixedLayoutPref = $wrapper.hasClass('container-limited');
      }
      $wrapper.removeClass('container-limited');
    }

    resetViewContainer() {
      if (this.fixedLayoutPref !== null) {
        $('.content-wrapper .container-fluid')
          .toggleClass('container-limited', this.fixedLayoutPref);
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
      if (Cookies.get('collapsed_gutter') === 'true') {
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
      if (Breakpoints.get().getBreakpointSize() === 'xs' || !$tabs.length) return;

      const $diffTabs = $('#diff-notes-app');
      const $fixedNav = $('.navbar-fixed-top');
      const $layoutNav = $('.layout-nav');

      $tabs.off('affix.bs.affix affix-top.bs.affix')
        .affix({
          offset: {
            top: () => (
              $diffTabs.offset().top - $tabs.height() - $fixedNav.height() - $layoutNav.height()
            ),
          },
        })
        .on('affix.bs.affix', () => $diffTabs.css({ marginTop: $tabs.height() }))
        .on('affix-top.bs.affix', () => $diffTabs.css({ marginTop: '' }));

      // Fix bug when reloading the page already scrolling
      if ($tabs.hasClass('affix')) {
        $tabs.trigger('affix.bs.affix');
      }
    }
  }

  window.gl = window.gl || {};
  window.gl.MergeRequestTabs = MergeRequestTabs;
})();
