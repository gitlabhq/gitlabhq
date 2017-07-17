/* eslint-disable max-len, space-before-function-paren, no-underscore-dangle, consistent-return, comma-dangle, no-unused-vars, dot-notation, no-new, no-return-assign, camelcase, no-param-reassign, class-methods-use-this */

/*
UserTabs

Handles persisting and restoring the current tab selection and lazily-loading
content on the Users#show page.

### Example Markup

   <ul class="nav-links">
     <li class="activity-tab active">
       <a data-action="activity" data-target="#activity" data-toggle="tab" href="/u/username">
         Activity
       </a>
     </li>
     <li class="groups-tab">
       <a data-action="groups" data-target="#groups" data-toggle="tab" href="/u/username/groups">
         Groups
       </a>
     </li>
     <li class="contributed-tab">
       <a data-action="contributed" data-target="#contributed" data-toggle="tab" href="/u/username/contributed">
         Contributed projects
       </a>
     </li>
     <li class="projects-tab">
       <a data-action="projects" data-target="#projects" data-toggle="tab" href="/u/username/projects">
         Personal projects
       </a>
     </li>
    <li class="snippets-tab">
       <a data-action="snippets" data-target="#snippets" data-toggle="tab" href="/u/username/snippets">
       </a>
     </li>
   </ul>

   <div class="tab-content">
     <div class="tab-pane" id="activity">
       Activity Content
     </div>
     <div class="tab-pane" id="groups">
       Groups Content
     </div>
     <div class="tab-pane" id="contributed">
       Contributed projects content
     </div>
     <div class="tab-pane" id="projects">
      Projects content
     </div>
     <div class="tab-pane" id="snippets">
       Snippets content
     </div>
  </div>

   <div class="loading-status">
     <div class="loading">
      Loading Animation
     </div>
   </div>
*/

export default class UserTabs {
  constructor ({ defaultAction, action, parentEl }) {
    this.loaded = {};
    this.defaultAction = defaultAction || 'activity';
    this.action = action || this.defaultAction;
    this.$parentEl = $(parentEl) || $(document);
    this._location = window.location;
    this.$parentEl.find('.nav-links a')
      .each((i, navLink) => {
        this.loaded[$(navLink).attr('data-action')] = false;
      });
    this.actions = Object.keys(this.loaded);
    this.bindEvents();

    if (this.action === 'show') {
      this.action = this.defaultAction;
    }

    this.activateTab(this.action);
  }

  bindEvents() {
    this.changeProjectsPageWrapper = this.changeProjectsPage.bind(this);

    this.$parentEl.off('shown.bs.tab', '.nav-links a[data-toggle="tab"]')
      .on('shown.bs.tab', '.nav-links a[data-toggle="tab"]', event => this.tabShown(event));

    this.$parentEl.on('click', '.gl-pagination a', this.changeProjectsPageWrapper);
  }

  changeProjectsPage(e) {
    e.preventDefault();

    $('.tab-pane.active').empty();
    const endpoint = $(e.target).attr('href');
    this.loadTab(this.getCurrentAction(), endpoint);
  }

  tabShown(event) {
    const $target = $(event.target);
    const action = $target.data('action');
    const source = $target.attr('href');
    const endpoint = $target.data('endpoint');
    this.setTab(action, endpoint);
    return this.setCurrentAction(source);
  }

  activateTab(action) {
    return this.$parentEl.find(`.nav-links .js-${action}-tab a`)
      .tab('show');
  }

  setTab(action, endpoint) {
    if (this.loaded[action]) {
      return;
    }
    if (action === 'activity') {
      this.loadActivities();
    }

    const loadableActions = ['groups', 'contributed', 'projects', 'snippets'];
    if (loadableActions.indexOf(action) > -1) {
      return this.loadTab(action, endpoint);
    }
  }

  loadTab(action, endpoint) {
    return $.ajax({
      beforeSend: () => this.toggleLoading(true),
      complete: () => this.toggleLoading(false),
      dataType: 'json',
      type: 'GET',
      url: endpoint,
      success: (data) => {
        const tabSelector = `div#${action}`;
        this.$parentEl.find(tabSelector).html(data.html);
        this.loaded[action] = true;
        return gl.utils.localTimeAgo($('.js-timeago', tabSelector));
      }
    });
  }

  loadActivities() {
    if (this.loaded['activity']) {
      return;
    }
    const $calendarWrap = this.$parentEl.find('.user-calendar');
    $calendarWrap.load($calendarWrap.data('href'));
    new gl.Activities();
    return this.loaded['activity'] = true;
  }

  toggleLoading(status) {
    return this.$parentEl.find('.loading-status .loading')
      .toggle(status);
  }

  setCurrentAction(source) {
    let new_state = source;
    new_state = new_state.replace(/\/+$/, '');
    new_state += this._location.search + this._location.hash;
    history.replaceState({
      url: new_state
    }, document.title, new_state);
    return new_state;
  }

  getCurrentAction() {
    return this.$parentEl.find('.nav-links .active a').data('action');
  }
}
