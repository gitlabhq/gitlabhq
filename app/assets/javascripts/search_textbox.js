class SearchTextBox {
  constructor({
    wrap,
  } = {}) {
    this.wrap = wrap || $('.search-textbox');
    this.searchInput = this.getElement('.search-textbox-input');
    this.clearInput = this.getElement('.js-clear-input');
  }

  // Finds an element inside wrapper element
  bindEventContext() {
    this.onSearchInputBlur = this.onSearchInputBlur.bind(this);
    this.onClearInputClick = this.onClearInputClick.bind(this);
    this.onSearchInputFocus = this.onSearchInputFocus.bind(this);
    this.onSearchInputClick = this.onSearchInputClick.bind(this);
    this.onSearchInputKeyUp = this.onSearchInputKeyUp.bind(this);
    this.onSearchInputKeyDown = this.onSearchInputKeyDown.bind(this);
  }
  getElement(selector) {
    return this.wrap.find(selector);
  }

  getSearchText(selectedObject, el) {
    return selectedObject.id ? selectedObject.text : '';
  }


  bindEvents() {
    this.searchInput.on('keydown', this.onSearchInputKeyDown);
    this.searchInput.on('keyup', this.onSearchInputKeyUp);
    this.searchInput.on('click', this.onSearchInputClick);
    this.searchInput.on('focus', this.onSearchInputFocus);
    this.searchInput.on('blur', this.onSearchInputBlur);
    this.clearInput.on('click', this.onClearInputClick);
  }

  onSearchInputKeyUp(e) {
    this.wrap.toggleClass('has-value', !!e.target.value);
  }

  // Avoid falsy value to be returned
  onSearchInputClick(e) {
    return e.stopImmediatePropagation();
  }

  onSearchInputFocus() {
    this.isFocused = true;
    this.wrap.addClass('search-active');
    if (this.getValue() === '') {
      return this.getData();
    }
  }

  getValue() {
    return this.searchInput.val();
  }

  onClearInputClick(e) {
    e.preventDefault();
    return this.searchInput.val('').focus();
  }

  onSearchInputBlur(e) {
    this.isFocused = false;
    this.wrap.removeClass('search-active');
  }

}

export default SearchTextBox;
