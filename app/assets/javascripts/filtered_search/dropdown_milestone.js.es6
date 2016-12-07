/* eslint-disable no-param-reassign */
/*= require filtered_search/filtered_search_dropdown */

((global) => {
  class DropdownMilestone extends gl.FilteredSearchDropdown {
    constructor(dropdown, input) {
      super(dropdown, input);
      this.listId = 'js-dropdown-milestone';
    }

    itemClicked(e) {
      const dataValueSet = this.setDataValueIfSelected(e.detail.selected);

      if (!dataValueSet) {
        const milestoneTitle = e.detail.selected.querySelector('.btn-link').innerText.trim();
        const milestoneName = `%${this.getEscapedText(milestoneTitle)}`;
        gl.FilteredSearchManager.addWordToInput(this.getSelectedText(milestoneName));
      }

      this.dismissDropdown();
    }

    renderContent() {
      super.renderContent();
      droplab.setData(this.hookId, 'milestones.json');
    }

    filterMethod(item, query) {
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1).toLowerCase();
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      const title = item.title.toLowerCase();

      const noTitleMatch = title.indexOf(valueWithoutPrefix) === -1 && title.indexOf(valueWithoutColon) === -1;

      item.droplab_hidden = noTitleMatch;
      return item;
    }
  }

  global.DropdownMilestone = DropdownMilestone;
})(window.gl || (window.gl = {}));
