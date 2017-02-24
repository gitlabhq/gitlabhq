class FilteredSearchVisualTokens {
  static getLastVisualToken() {
    const tokensContainer = document.querySelector('.tokens-container');
    const visualTokens = tokensContainer.children;
    const lastVisualToken = visualTokens[visualTokens.length - 1];
    return {
      lastVisualToken,
      isLastVisualTokenValid: visualTokens.length === 0 || lastVisualToken.className.indexOf('filtered-search-term') !== -1 || (lastVisualToken && lastVisualToken.querySelector('.value') !== null),
    };
  }

  static unselectTokens() {
    const otherTokens = document.querySelectorAll('.js-visual-token .selectable.selected');
    [].forEach.call(otherTokens, t => t.classList.remove('selected'));
  }

  static selectToken(tokenButton) {
    const selected = tokenButton.classList.contains('selected');
    FilteredSearchVisualTokens.unselectTokens();

    if (!selected) {
      tokenButton.classList.add('selected');
    }
  }

  static removeSelectedToken() {
    const selected = document.querySelector('.js-visual-token .selected');

    if (selected) {
      const li = selected.closest('.js-visual-token');
      li.parentElement.removeChild(li);
    }
  }

  static addVisualTokenElement(name, value, isSearchTerm) {
    const li = document.createElement('li');
    li.classList.add('js-visual-token');
    li.classList.add(isSearchTerm ? 'filtered-search-term' : 'filtered-search-token');

    if (value) {
      li.innerHTML = `
        <div class="selectable" role="button">
          <div class="name"></div>
          <div class="value"></div>
        </div>
      `;
      li.querySelector('.value').innerText = value;
    } else {
      li.innerHTML = '<div class="name"></div>';
    }
    li.querySelector('.name').innerText = name;

    const tokensContainer = document.querySelector('.tokens-container');
    tokensContainer.appendChild(li);
  }

  static addFilterVisualToken(tokenName, tokenValue) {
    const { lastVisualToken, isLastVisualTokenValid }
      = FilteredSearchVisualTokens.getLastVisualToken();
    const addVisualTokenElement = FilteredSearchVisualTokens.addVisualTokenElement;

    if (isLastVisualTokenValid) {
      addVisualTokenElement(tokenName, tokenValue);
    } else {
      const previousTokenName = lastVisualToken.querySelector('.name').innerText;
      const tokensContainer = document.querySelector('.tokens-container');
      tokensContainer.removeChild(lastVisualToken);

      const value = tokenValue || tokenName;
      addVisualTokenElement(previousTokenName, value);
    }
  }

  static addSearchVisualToken(searchTerm) {
    FilteredSearchVisualTokens.addVisualTokenElement(searchTerm, null, true);
  }

  static getLastTokenPartial() {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualToken();

    if (!lastVisualToken) return '';

    const value = lastVisualToken.querySelector('.value');
    const name = lastVisualToken.querySelector('.name');

    const valueText = value ? value.innerText : '';
    const nameText = name ? name.innerText : '';

    return valueText || nameText;
  }

  static removeLastTokenPartial() {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualToken();

    if (lastVisualToken) {
      const value = lastVisualToken.querySelector('.value');

      if (value) {
        const button = lastVisualToken.querySelector('.selectable');
        button.removeChild(value);
        lastVisualToken.innerHTML = button.innerHTML;
      } else {
        lastVisualToken.closest('.tokens-container').removeChild(lastVisualToken);
      }
    }
  }
}

window.gl = window.gl || {};
gl.FilteredSearchVisualTokens = FilteredSearchVisualTokens;
