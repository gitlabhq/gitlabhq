/* eslint-disable max-len, func-names, space-before-function-paren, no-var, space-before-blocks, prefer-rest-params, wrap-iife, no-use-before-define, no-underscore-dangle, no-undef, one-var, one-var-declaration-per-line, quotes, comma-dangle, consistent-return, prefer-template, no-param-reassign, camelcase, vars-on-top, space-in-parens, curly, prefer-arrow-callback, no-unused-vars, no-return-assign, semi, object-shorthand, operator-assignment, padded-blocks, max-len */
// MergeRequestTabs
//
// Handles persisting and restoring the current tab selection and lazily-loading
// content on the MergeRequests#show page.
//
/*= require js.cookie */

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
((global) => {

  class MergeRequestTabs {

    constructor({ action, setUrl, buildsLoaded } = {}) {
      this.diffsLoaded = false;
      this.buildsLoaded = false;
      this.pipelinesLoaded = false;
      this.commitsLoaded = false;
      this.fixedLayoutPref = null;

      this.setUrl = setUrl !== undefined ? setUrl : true;
      this.buildsLoaded = buildsLoaded || false;

      this.setCurrentAction = this.setCurrentAction.bind(this);
      this.tabShown = this.tabShown.bind(this);
      this.showTab = this.showTab.bind(this);

      // Store the `location` object, allowing for easier stubbing in tests
      this._location = window.location;
      this.bindEvents();
      this.activateTab(action);
      this.initAffix();
    }

    bindEvents() {
      $(document)
        .on('shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', this.tabShown)
        .on('click', '.js-show-tab', this.showTab);
    }

    unbindEvents() {
      $(document)
        .off('shown.bs.tab', '.merge-request-tabs a[data-toggle="tab"]', this.tabShown)
        .off('click', '.js-show-tab', this.showTab);
    }

    showTab(event) {
      event.preventDefault();
      this.activateTab($(event.target).data('action'));
    }

    tabShown(event) {
      var $target, action, navBarHeight;
      $target = $(event.target);
      action = $target.data('action');
      if (action === 'commits') {
        this.loadCommits($target.attr('href'));
        this.expandView();
        this.resetViewContainer();
      } else if (this.isDiffAction(action)) {
        this.loadDiff($target.attr('href'));
        if ((typeof bp !== "undefined" && bp !== null) && bp.getBreakpointSize() !== 'lg') {
          this.shrinkView();
        }
        if (this.diffViewType() === 'parallel') {
          this.expandViewContainer();
        }
        navBarHeight = $('.navbar-gitlab').outerHeight();
        $.scrollTo(".merge-request-details .merge-request-tabs", {
          offset: -navBarHeight
        });
      } else if (action === 'builds') {
        this.loadBuilds($target.attr('href'));
        this.expandView();
        this.resetViewContainer();
      } else if (action === 'pipelines') {
        this.loadPipelines($target.attr('href'));
        this.expandView();
        this.resetViewContainer();
      } else {
        this.expandView();
        this.resetViewContainer();
      }
      if (this.setUrl) {
        this.setCurrentAction(action);
      }
    }

    scrollToElement(container) {
      var $el, navBarHeight;
      if (window.location.hash) {
        navBarHeight = $('.navbar-gitlab').outerHeight() + $('.layout-nav').outerHeight() + document.querySelector('.js-tabs-affix').offsetHeight;
        $el = $(container + " " + window.location.hash + ":not(.match)");
        if ($el.length) {
          return $.scrollTo(container + " " + window.location.hash + ":not(.match)", {
            offset: -navBarHeight
          });
        }
      }
    }

    // Activate a tab based on the current action
    activateTab(action) {
      if (action === 'show') {
        action = 'notes';
      }
      // important note: the .tab('show') method triggers 'shown.bs.tab' event itself
      $(".merge-request-tabs a[data-action='" + action + "']").tab('show');
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
      var new_state;
      // Normalize action, just to be safe
      if (action === 'show') {
        action = 'notes';
      }
      this.currentAction = action;
      // Remove a trailing '/commits' '/diffs' '/builds' '/pipelines' '/new' '/new/diffs'
      new_state = this._location.pathname.replace(/\/(commits|diffs|builds|pipelines|new|new\/diffs)(\.html)?\/?$/, '');

      // Append the new action if we're on a tab other than 'notes'
      if (action !== 'notes') {
        new_state += "/" + action;
      }
      // Ensure parameters and hash come along for the ride
      new_state += this._location.search + this._location.hash;

      // Replace the current history state with the new one without breaking
      // Turbolinks' history.
      //
      // See https://github.com/rails/turbolinks/issues/363
      history.replaceState({
        turbolinks: true,
        url: new_state
      }, document.title, new_state);

      return new_state;
    }

    loadCommits(source) {
      if (this.commitsLoaded) {
        return;
      }
      this.ajaxGet({
        url: source + ".json",
        success: (data) => {
          document.querySelector("div#commits").innerHTML = data.html;
          gl.utils.localTimeAgo($('.js-timeago', 'div#commits'));
          this.commitsLoaded = true;
          this.scrollToElement("#commits");
        }
      });
    }

    loadDiff(source) {
      if (this.diffsLoaded) {
        return;
      }

      // We extract pathname for the current Changes tab anchor href
      // some pages like MergeRequestsController#new has query parameters on that anchor
      var url = document.createElement('a');
      url.href = source;

      this.ajaxGet({
        url: (url.pathname + ".json") + this._location.search,
        success: (data) => {
          $('#diffs').html(data.html);

          if (typeof gl.diffNotesCompileComponents !== 'undefined') {
            gl.diffNotesCompileComponents();
          }

          gl.utils.localTimeAgo($('.js-timeago', 'div#diffs'));
          $('#diffs .js-syntax-highlight').syntaxHighlight();

          if (this.diffViewType() === 'parallel' && this.isDiffAction(this.currentAction) ) {
            this.expandViewContainer();
          }
          this.diffsLoaded = true;
          this.scrollToElement("#diffs");

          new Diff();
        }
      });
    }

    loadBuilds(source) {
      if (this.buildsLoaded) {
        return;
      }
      this.ajaxGet({
        url: source + ".json",
        success: (data) => {
          document.querySelector("div#builds").innerHTML = data.html;
          gl.utils.localTimeAgo($('.js-timeago', 'div#builds'));
          this.buildsLoaded = true;
          new gl.Pipelines();
          this.scrollToElement("#builds");
        }
      });
    }

    loadPipelines(source) {
      if (this.pipelinesLoaded) {
        return;
      }
      this.ajaxGet({
        url: source + ".json",
        success: (data) => {
          $('#pipelines').html(data.html);
          gl.utils.localTimeAgo($('.js-timeago', '#pipelines'));
          this.pipelinesLoaded = true;
          this.scrollToElement("#pipelines");
        }
      });
    }

    // Show or hide the loading spinner
    //
    // status - Boolean, true to show, false to hide
    toggleLoading(status) {
      $('.mr-loading-status .loading').toggle(status);
    }

    ajaxGet(options) {
      var defaults = {
        beforeSend: () => this.toggleLoading(true),
        complete: () => this.toggleLoading(false),
        dataType: 'json',
        type: 'GET'
      };
      options = $.extend({}, defaults, options);
      $.ajax(options);
    }

    diffViewType() {
      return $('.inline-parallel-buttons a.active').data('view-type');
    }

    isDiffAction(action) {
      return action === 'diffs' || action === 'new/diffs'
    }

    expandViewContainer() {
      var $wrapper = $('.content-wrapper .container-fluid');
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
      var $gutterIcon;
      $gutterIcon = $('.js-sidebar-toggle i:visible');

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
      var $gutterIcon;
      if (Cookies.get('collapsed_gutter') === 'true') {
        return;
      }
      $gutterIcon = $('.js-sidebar-toggle i:visible');

      // Wait until listeners are set
      setTimeout(() => {
        // Only when sidebar is collapsed
        if ($gutterIcon.is('.fa-angle-double-left')) {
          $gutterIcon.closest('a').trigger('click', [true]);
        }
      }, 0);
    }

    initAffix() {
      var $tabs = $('.js-tabs-affix');

      // Screen space on small screens is usually very sparse
      // So we dont affix the tabs on these
      if (Breakpoints.get().getBreakpointSize() === 'xs' || !$tabs.length) return;

      var $diffTabs = $('#diff-notes-app'),
        $fixedNav = $('.navbar-fixed-top'),
        $layoutNav = $('.layout-nav');

      $tabs.off('affix.bs.affix affix-top.bs.affix')
        .affix({ offset: {
          top: () => (
            $diffTabs.offset().top - $tabs.height() - $fixedNav.height() - $layoutNav.height()
          )
        }})
        .on('affix.bs.affix', () => $diffTabs.css({ marginTop: $tabs.height() }))
        .on('affix-top.bs.affix', () => $diffTabs.css({ marginTop: '' }));

      // Fix bug when reloading the page already scrolling
      if ($tabs.hasClass('affix')) {
        $tabs.trigger('affix.bs.affix');
      }
    }
  }

  global.MergeRequestTabs = MergeRequestTabs;

})(window.gl || (window.gl = {}));
