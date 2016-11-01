((global) => {
  const TOKEN_KEYS = ['author', 'assignee', 'milestone', 'label', 'weight'];

  class FilteredSearchManager {
    constructor() {
      this.canDeleteTokenIfExists = false;
      this.bindEvents();
    }

    bindEvents() {
      const input = document.querySelector('.filtered-search');

      input.addEventListener('focus', this.toggleContainerHighlight);
      input.addEventListener('blur', this.toggleContainerHighlight);
      input.addEventListener('input', this.checkTokens.bind(this));
      input.addEventListener('keyup', this.inputKeyup.bind(this));
      input.addEventListener('keydown', this.inputKeydown.bind(this));
    }

    toggleContainerHighlight(event) {
      const container = document.querySelector('.filtered-search-container');
      container.classList.toggle('focus');
    }

    inputKeydown(event) {
      if (event.key === 'Backspace' && event.target.value === '') {
        this.canDeleteTokenIfExists = true;
      } else {
        this.canDeleteTokenIfExists = false;
      }
    }

    inputKeyup(event) {
      if (event.key === 'Enter') {
        this.search();
      } else if (this.canDeleteTokenIfExists) {
        this.deleteToken(event.target);
      }
    }

    checkTokens(event) {
      const text = event.target.value.toLowerCase();
      const hasColon = text[text.length - 1] === ':';

      if (hasColon && TOKEN_KEYS.indexOf(text.slice(0, -1)) != -1) {
        event.target.value = '';

        const tokenKey = text.charAt(0).toUpperCase() + text.slice(1, -1);
        this.addToken(tokenKey, event.target);
      }
    }

    addToken(key, inputNode) {
      const listItem = inputNode.parentNode;
      const fragmentList = listItem.parentNode;

      let fragmentToken = document.createElement('li');
      fragmentToken.classList.add('fragment-token');

      let fragmentKey = document.createElement('span');
      fragmentKey.classList.add('fragment-key');
      fragmentKey.innerText = key;

      fragmentToken.appendChild(fragmentKey);
      fragmentList.insertBefore(fragmentToken, listItem);
    }

    deleteToken(inputNode) {
      const listItem = inputNode.parentNode;
      const fragmentList = listItem.parentNode;
      const fragments = fragmentList.childNodes.length;

      if (fragments === 1) {
        // Only input fragment found in fragmentList
        return;
      }

      fragmentList.removeChild(listItem.previousSibling);
    }

    search() {
      console.log('search');
    }
  }

  global.FilteredSearchManager = FilteredSearchManager;
})(window.gl || (window.gl = {}));
