import $ from 'jquery';

const defaults = {
  // Buttons that will show the `suggestionSections`
  // has `data-fork-path`, and `data-action`
  openButtons: [],
  // Update the href(from `openButton` -> `data-fork-path`)
  // whenever a `openButton` is clicked
  forkButtons: [],
  // Buttons to hide the `suggestionSections`
  cancelButtons: [],
  // Section to show/hide
  suggestionSections: [],
  // Pieces of text that need updating depending on the action, `edit`, `replace`, `delete`
  actionTextPieces: [],
};

class BlobForkSuggestion {
  constructor(options) {
    this.elementMap = Object.assign({}, defaults, options);
    this.onOpenButtonClick = this.onOpenButtonClick.bind(this);
    this.onCancelButtonClick = this.onCancelButtonClick.bind(this);
  }

  init() {
    this.bindEvents();

    return this;
  }

  bindEvents() {
    $(this.elementMap.openButtons).on('click', this.onOpenButtonClick);
    $(this.elementMap.cancelButtons).on('click', this.onCancelButtonClick);
  }

  showSuggestionSection(forkPath, action = 'edit') {
    $(this.elementMap.suggestionSections).removeClass('hidden');
    $(this.elementMap.forkButtons).attr('href', forkPath);
    $(this.elementMap.actionTextPieces).text(action);
  }

  hideSuggestionSection() {
    $(this.elementMap.suggestionSections).addClass('hidden');
  }

  onOpenButtonClick(e) {
    const forkPath = $(e.currentTarget).attr('data-fork-path');
    const action = $(e.currentTarget).attr('data-action');
    this.showSuggestionSection(forkPath, action);
  }

  onCancelButtonClick() {
    this.hideSuggestionSection();
  }

  destroy() {
    $(this.elementMap.openButtons).off('click', this.onOpenButtonClick);
    $(this.elementMap.cancelButtons).off('click', this.onCancelButtonClick);
  }
}

export default BlobForkSuggestion;
