/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownAssignee extends gl.FilteredSearchDropdown {
    constructor(dropdown, input) {
      super(dropdown, input);
      this.listId = 'js-dropdown-assignee';
    }

    itemClicked(e) {
      console.log('assignee clicked');
    }

    renderContent() {
      droplab.addData(this.hookId, '/autocomplete/users.json?search=&per_page=20&active=true&project_id=2&group_id=&skip_ldap=&todo_filter=&todo_state_filter=&current_user=true&push_code_to_protected_branches=&author_id=&skip_users=');
    }
  }

  global.DropdownAssignee = DropdownAssignee;
})(window.gl || (window.gl = {}));
