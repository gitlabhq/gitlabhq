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

  static addVisualTokenElement(name, value, isSearchTerm) {
    const li = document.createElement('li');
    li.classList.add('js-visual-token');
    li.classList.add(isSearchTerm ? 'filtered-search-term' : 'filtered-search-token');
    li.innerHTML = '<div class="name"></div>';
    li.querySelector('.name').innerText = name;

    if (value) {
      li.innerHTML += '<div class="value"></div>';
      li.querySelector('.value').innerText = value;
    }

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
}

window.gl = window.gl || {};
gl.FilteredSearchVisualTokens = FilteredSearchVisualTokens;
