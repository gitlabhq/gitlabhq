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

// Callers may pass a single Element, a NodeList, or an Array — normalize all three.
const toElementArray = (value) => {
  if (!value) return [];
  if (value instanceof Element) return [value];
  return Array.from(value);
};

class BlobForkSuggestion {
  constructor(options) {
    this.elementMap = { ...defaults, ...options };
    this.onOpenButtonClick = this.onOpenButtonClick.bind(this);
    this.onCancelButtonClick = this.onCancelButtonClick.bind(this);
  }

  init() {
    this.bindEvents();

    return this;
  }

  bindEvents() {
    toElementArray(this.elementMap.openButtons).forEach((el) =>
      el.addEventListener('click', this.onOpenButtonClick),
    );
    toElementArray(this.elementMap.cancelButtons).forEach((el) =>
      el.addEventListener('click', this.onCancelButtonClick),
    );
  }

  showSuggestionSection(forkPath, action = 'edit') {
    toElementArray(this.elementMap.suggestionSections).forEach((el) =>
      el.classList.remove('hidden'),
    );
    toElementArray(this.elementMap.forkButtons).forEach((el) => el.setAttribute('href', forkPath));
    toElementArray(this.elementMap.actionTextPieces).forEach((el) => {
      el.textContent = action;
    });
  }

  hideSuggestionSection() {
    toElementArray(this.elementMap.suggestionSections).forEach((el) => el.classList.add('hidden'));
  }

  onOpenButtonClick(e) {
    const { forkPath, action } = e.currentTarget.dataset;
    this.showSuggestionSection(forkPath, action);
  }

  onCancelButtonClick() {
    this.hideSuggestionSection();
  }

  destroy() {
    toElementArray(this.elementMap.openButtons).forEach((el) =>
      el.removeEventListener('click', this.onOpenButtonClick),
    );
    toElementArray(this.elementMap.cancelButtons).forEach((el) =>
      el.removeEventListener('click', this.onCancelButtonClick),
    );
  }
}

export default BlobForkSuggestion;
