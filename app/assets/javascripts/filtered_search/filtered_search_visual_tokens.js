import AjaxCache from '../lib/utils/ajax_cache';
import '../flash'; /* global Flash */
import FilteredSearchContainer from './container';
import UsersCache from '../lib/utils/users_cache';

class FilteredSearchVisualTokens {
  static getLastVisualTokenBeforeInput() {
    const inputLi = FilteredSearchContainer.container.querySelector('.input-token');
    const lastVisualToken = inputLi && inputLi.previousElementSibling;

    return {
      lastVisualToken,
      isLastVisualTokenValid: lastVisualToken === null || lastVisualToken.className.indexOf('filtered-search-term') !== -1 || (lastVisualToken && lastVisualToken.querySelector('.value') !== null),
    };
  }

  static unselectTokens() {
    const otherTokens = FilteredSearchContainer.container.querySelectorAll('.js-visual-token .selectable.selected');
    [].forEach.call(otherTokens, t => t.classList.remove('selected'));
  }

  static selectToken(tokenButton, forceSelection = false) {
    const selected = tokenButton.classList.contains('selected');
    FilteredSearchVisualTokens.unselectTokens();

    if (!selected || forceSelection) {
      tokenButton.classList.add('selected');
    }
  }

  static removeSelectedToken() {
    const selected = FilteredSearchContainer.container.querySelector('.js-visual-token .selected');

    if (selected) {
      const li = selected.closest('.js-visual-token');
      li.parentElement.removeChild(li);
    }
  }

  static createVisualTokenElementHTML(canEdit = true) {
    let removeTokenMarkup = '';
    if (canEdit) {
      removeTokenMarkup = `
        <div class="remove-token" role="button">
          <i class="fa fa-close"></i>
        </div>
      `;
    }

    return `
      <div class="selectable" role="button">
        <div class="name"></div>
        <div class="value-container">
          <div class="value"></div>
          ${removeTokenMarkup}
        </div>
      </div>
    `;
  }

  static updateLabelTokenColor(tokenValueContainer, tokenValue) {
    const filteredSearchInput = FilteredSearchContainer.container.querySelector('.filtered-search');
    const baseEndpoint = filteredSearchInput.dataset.baseEndpoint;
    const labelsEndpoint = `${baseEndpoint}/labels.json`;

    return AjaxCache.retrieve(labelsEndpoint)
    .then((labels) => {
      const matchingLabel = (labels || []).find(label => `~${gl.DropdownUtils.getEscapedText(label.title)}` === tokenValue);

      if (!matchingLabel) {
        return;
      }

      const tokenValueStyle = tokenValueContainer.style;
      tokenValueStyle.backgroundColor = matchingLabel.color;
      tokenValueStyle.color = matchingLabel.text_color;

      if (matchingLabel.text_color === '#FFFFFF') {
        const removeToken = tokenValueContainer.querySelector('.remove-token');
        removeToken.classList.add('inverted');
      }
    })
    .catch(() => new Flash('An error occurred while fetching label colors.'));
  }

  static updateUserTokenAppearance(tokenValueContainer, tokenValueElement, tokenValue) {
    if (tokenValue === 'none') {
      return Promise.resolve();
    }

    const username = tokenValue.replace(/^@/, '');
    return UsersCache.retrieve(username)
      .then((user) => {
        if (!user) {
          return;
        }

        /* eslint-disable no-param-reassign */
        tokenValueContainer.dataset.originalValue = tokenValue;
        tokenValueElement.innerHTML = `
          <img class="avatar s20" src="${user.avatar_url}" alt="">
          ${_.escape(user.name)}
        `;
        /* eslint-enable no-param-reassign */
      })
      // ignore error and leave username in the search bar
      .catch(() => { });
  }

  static renderVisualTokenValue(parentElement, tokenName, tokenValue) {
    const tokenValueContainer = parentElement.querySelector('.value-container');
    const tokenValueElement = tokenValueContainer.querySelector('.value');
    tokenValueElement.innerText = tokenValue;

    const tokenType = tokenName.toLowerCase();
    if (tokenType === 'label') {
      FilteredSearchVisualTokens.updateLabelTokenColor(tokenValueContainer, tokenValue);
    } else if ((tokenType === 'author') || (tokenType === 'assignee')) {
      FilteredSearchVisualTokens.updateUserTokenAppearance(
        tokenValueContainer, tokenValueElement, tokenValue,
      );
    }
  }

  static addVisualTokenElement(name, value, isSearchTerm, canEdit) {
    const li = document.createElement('li');
    li.classList.add('js-visual-token');
    li.classList.add(isSearchTerm ? 'filtered-search-term' : 'filtered-search-token');

    if (value) {
      li.innerHTML = FilteredSearchVisualTokens.createVisualTokenElementHTML(canEdit);
      FilteredSearchVisualTokens.renderVisualTokenValue(li, name, value);
    } else {
      li.innerHTML = '<div class="name"></div>';
    }
    li.querySelector('.name').innerText = name;

    const tokensContainer = FilteredSearchContainer.container.querySelector('.tokens-container');
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');
    tokensContainer.insertBefore(li, input.parentElement);
  }

  static addValueToPreviousVisualTokenElement(value) {
    const { lastVisualToken, isLastVisualTokenValid } =
      FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (!isLastVisualTokenValid && lastVisualToken.classList.contains('filtered-search-token')) {
      const name = FilteredSearchVisualTokens.getLastTokenPartial();
      lastVisualToken.innerHTML = FilteredSearchVisualTokens.createVisualTokenElementHTML();
      lastVisualToken.querySelector('.name').innerText = name;
      FilteredSearchVisualTokens.renderVisualTokenValue(lastVisualToken, name, value);
    }
  }

  static addFilterVisualToken(tokenName, tokenValue, canEdit) {
    const { lastVisualToken, isLastVisualTokenValid }
      = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();
    const addVisualTokenElement = FilteredSearchVisualTokens.addVisualTokenElement;

    if (isLastVisualTokenValid) {
      addVisualTokenElement(tokenName, tokenValue, false, canEdit);
    } else {
      const previousTokenName = lastVisualToken.querySelector('.name').innerText;
      const tokensContainer = FilteredSearchContainer.container.querySelector('.tokens-container');
      tokensContainer.removeChild(lastVisualToken);

      const value = tokenValue || tokenName;
      addVisualTokenElement(previousTokenName, value, false, canEdit);
    }
  }

  static addSearchVisualToken(searchTerm) {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (lastVisualToken && lastVisualToken.classList.contains('filtered-search-term')) {
      lastVisualToken.querySelector('.name').innerText += ` ${searchTerm}`;
    } else {
      FilteredSearchVisualTokens.addVisualTokenElement(searchTerm, null, true);
    }
  }

  static getLastTokenPartial() {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (!lastVisualToken) return '';

    const valueContainer = lastVisualToken.querySelector('.value-container');
    const originalValue = valueContainer && valueContainer.dataset.originalValue;
    if (originalValue) {
      return originalValue;
    }

    const value = lastVisualToken.querySelector('.value');
    const name = lastVisualToken.querySelector('.name');

    const valueText = value ? value.innerText : '';
    const nameText = name ? name.innerText : '';

    return valueText || nameText;
  }

  static removeLastTokenPartial() {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (lastVisualToken) {
      const value = lastVisualToken.querySelector('.value');

      if (value) {
        const button = lastVisualToken.querySelector('.selectable');
        const valueContainer = lastVisualToken.querySelector('.value-container');
        button.removeChild(valueContainer);
        lastVisualToken.innerHTML = button.innerHTML;
      } else {
        lastVisualToken.closest('.tokens-container').removeChild(lastVisualToken);
      }
    }
  }

  static tokenizeInput() {
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');
    const { isLastVisualTokenValid } =
      gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (input.value) {
      if (isLastVisualTokenValid) {
        gl.FilteredSearchVisualTokens.addSearchVisualToken(input.value);
      } else {
        FilteredSearchVisualTokens.addValueToPreviousVisualTokenElement(input.value);
      }

      input.value = '';
    }
  }

  static editToken(token) {
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');

    FilteredSearchVisualTokens.tokenizeInput();

    // Replace token with input field
    const tokenContainer = token.parentElement;
    const inputLi = input.parentElement;
    tokenContainer.replaceChild(inputLi, token);

    const nameElement = token.querySelector('.name');
    let value;

    if (token.classList.contains('filtered-search-token')) {
      FilteredSearchVisualTokens.addFilterVisualToken(nameElement.innerText);

      const valueContainerElement = token.querySelector('.value-container');
      value = valueContainerElement.dataset.originalValue;

      if (!value) {
        const valueElement = valueContainerElement.querySelector('.value');
        value = valueElement.innerText;
      }
    }

    // token is a search term
    if (!value) {
      value = nameElement.innerText;
    }

    input.value = value;

    // Opens dropdown
    const inputEvent = new Event('input');
    input.dispatchEvent(inputEvent);

    // Adds cursor to input
    input.focus();
  }

  static moveInputToTheRight() {
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');

    if (!input) return;

    const inputLi = input.parentElement;
    const tokenContainer = FilteredSearchContainer.container.querySelector('.tokens-container');

    FilteredSearchVisualTokens.tokenizeInput();

    if (!tokenContainer.lastElementChild.isEqualNode(inputLi)) {
      const { isLastVisualTokenValid } =
        gl.FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

      if (!isLastVisualTokenValid) {
        const lastPartial = gl.FilteredSearchVisualTokens.getLastTokenPartial();
        gl.FilteredSearchVisualTokens.removeLastTokenPartial();
        gl.FilteredSearchVisualTokens.addSearchVisualToken(lastPartial);
      }

      tokenContainer.removeChild(inputLi);
      tokenContainer.appendChild(inputLi);
    }
  }
}

window.gl = window.gl || {};
gl.FilteredSearchVisualTokens = FilteredSearchVisualTokens;
