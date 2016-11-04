((global) => {
  class FilteredSearchManager {
    constructor() {
      this.canDeleteTokenIfExists = false;
      this.bindEvents();
    }

    bindEvents() {
      const input = document.querySelector('.filtered-search');

      input.addEventListener('focus', this.toggleContainerHighlight);
      input.addEventListener('blur', this.toggleContainerHighlight);
      input.addEventListener('input', gl.Tokenizer.checkTokens);
      input.addEventListener('keyup', this.inputKeyup.bind(this));
      input.addEventListener('keydown', this.inputKeydown.bind(this));
    }

    toggleContainerHighlight(event) {
      const container = document.querySelector('.filtered-search-container');
      container.classList.toggle('focus');
    }

    inputKeydown(event) {
      const fragmentList = event.target.parentNode.parentNode;
      if (event.key === 'Backspace' && event.target.value === '' && fragmentList.childElementCount > 1) {
        this.canDeleteTokenIfExists = true;
      } else {
        this.canDeleteTokenIfExists = false;
      }

      if (event.key === 'Enter') {
        this.search();
        event.stopPropagation();
        event.preventDefault();
      }
    }

    inputKeyup(event) {
      if (this.canDeleteTokenIfExists) {
        gl.Tokenizer.deleteToken(event.target);
      }

      const fragmentList = event.target.parentNode.parentNode;
      if (fragmentList.childElementCount === 1) {
        event.target.placeholder = 'Search or filter results...';
      }
    }

    search() {
      console.log('search');
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));
