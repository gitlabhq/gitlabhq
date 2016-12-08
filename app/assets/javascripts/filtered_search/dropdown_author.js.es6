/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownAuthor extends gl.FilteredSearchDropdown {
    constructor(droplab, dropdown, input) {
      super(droplab, dropdown, input);
      this.listId = 'js-dropdown-author';
    }

    itemClicked(e) {
      const username = e.detail.selected.querySelector('.dropdown-light-content').innerText.trim();
      gl.FilteredSearchManager.addWordToInput(this.getSelectedText(username));

      this.dismissDropdown();
    }

    renderContent() {
      // TODO: Pass elements instead of querySelectors
      this.droplab.changeHookList(this.hookId, '#js-dropdown-author', [droplabAjax], {
        droplabAjax: {
          endpoint: '/autocomplete/users.json?search=&per_page=20&active=true&project_id=2&group_id=&skip_ldap=&todo_filter=&todo_state_filter=&current_user=true&push_code_to_protected_branches=&author_id=&skip_users=',
          method: 'setData',
        }
      });
    }

    filterMethod(item, query) {
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1).toLowerCase();
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      const username = item.username.toLowerCase();
      const name = item.name.toLowerCase();

      const noUsernameMatch = username.indexOf(valueWithoutPrefix) === -1 && username.indexOf(valueWithoutColon) === -1;
      const noNameMatch = name.indexOf(valueWithoutColon) === -1;

      item.droplab_hidden = noUsernameMatch && noNameMatch;
      return item;
    }
  }

  global.DropdownAuthor = DropdownAuthor;
})(window.gl || (window.gl = {}));
