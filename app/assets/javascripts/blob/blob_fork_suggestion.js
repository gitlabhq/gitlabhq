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
    this.onClickWrapper = this.onClick.bind(this);

    document.addEventListener('click', this.onClickWrapper);
  }

  showSuggestionSection(forkPath, action = 'edit') {
    [].forEach.call(this.elementMap.suggestionSections, (suggestionSection) => {
      suggestionSection.classList.remove('hidden');
    });

    [].forEach.call(this.elementMap.forkButtons, (forkButton) => {
      forkButton.setAttribute('href', forkPath);
    });

    [].forEach.call(this.elementMap.actionTextPieces, (actionTextPiece) => {
      // eslint-disable-next-line no-param-reassign
      actionTextPiece.textContent = action;
    });
  }

  hideSuggestionSection() {
    [].forEach.call(this.elementMap.suggestionSections, (suggestionSection) => {
      suggestionSection.classList.add('hidden');
    });
  }

  onClick(e) {
    const el = e.target;

    if ([].includes.call(this.elementMap.openButtons, el)) {
      const { forkPath, action } = el.dataset;
      this.showSuggestionSection(forkPath, action);
    }

    if ([].includes.call(this.elementMap.cancelButtons, el)) {
      this.hideSuggestionSection();
    }
  }

  destroy() {
    document.removeEventListener('click', this.onClickWrapper);
  }
}

export default BlobForkSuggestion;
