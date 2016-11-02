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
        this.deleteToken(event.target);
      }

      const fragmentList = event.target.parentNode.parentNode;
      if (fragmentList.childElementCount === 1) {
        event.target.placeholder = 'Search or filter results...';
      }
    }

    checkTokens(event) {
      const value = event.target.value;

      const split = value.toLowerCase().split(' ');
      const text = split.length === 1 ? split[0] : split[split.length - 1];
      const hasColon = text[text.length - 1] === ':';
      const token = text.slice(0, -1);

      if (hasColon && TOKEN_KEYS.indexOf(token) != -1) {
        // One for the colon and one for the space before it
        const textWithoutToken = value.substring(0, value.length - token.length - 2)
        this.addTextToken(textWithoutToken, event.target);

        const tokenKey = token.charAt(0).toUpperCase() + token.slice(1);
        this.addToken(tokenKey, event.target);

        event.target.value = '';
        event.target.placeholder = '';

        event.target.nextElementSibling.innerHTML += `<li><span>test</span></li>`;
        droplab.addHook(event.target);
      }
    }

    addTextToken(text, inputNode) {
      const listItem = inputNode.parentNode;
      const fragmentList = listItem.parentNode;

      let fragmentToken = document.createElement('li');
      fragmentToken.innerHTML = `<span>${text}</span>`

      fragmentList.insertBefore(fragmentToken, listItem);
    }

    addToken(key, inputNode) {
      const listItem = inputNode.parentNode;
      const fragmentList = listItem.parentNode;

      let fragmentToken = document.createElement('li');
      fragmentToken.classList.add('fragment-token');
      fragmentToken.innerHTML = `<span class="fragment-key">${key}</span>`

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
