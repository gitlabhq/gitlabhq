import { spriteIcon } from '~/lib/utils/common_utils';
import { objectToQuery } from '~/lib/utils/url_utility';
import FilteredSearchContainer from './container';
import VisualTokenValue from './visual_token_value';

export default class FilteredSearchVisualTokens {
  static permissibleOperatorValues = ['=', '!='];

  static getOperatorToken(value) {
    let token = null;

    FilteredSearchVisualTokens.permissibleOperatorValues.forEach((operatorToken) => {
      if (value.startsWith(operatorToken)) {
        token = operatorToken;
      }
    });

    return token;
  }

  static getValueToken(value) {
    let newValue = value;

    FilteredSearchVisualTokens.permissibleOperatorValues.forEach((operatorToken) => {
      if (value.startsWith(operatorToken)) {
        newValue = value.slice(operatorToken.length);
      }
    });

    return newValue;
  }

  static getLastVisualTokenBeforeInput() {
    const inputLi = FilteredSearchContainer.container.querySelector('.input-token');
    const lastVisualToken = inputLi && inputLi.previousElementSibling;

    return {
      lastVisualToken,
      isLastVisualTokenValid:
        lastVisualToken === null ||
        lastVisualToken.className.indexOf('filtered-search-term') !== -1 ||
        (lastVisualToken &&
          lastVisualToken.querySelector('.operator') !== null &&
          lastVisualToken.querySelector('.value') !== null),
    };
  }

  static unselectTokens() {
    const otherTokens = FilteredSearchContainer.container.querySelectorAll(
      '.js-visual-token .selectable.selected',
    );
    [].forEach.call(otherTokens, (t) => t.classList.remove('selected'));
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

  static createVisualTokenElementHTML(options = {}) {
    const {
      canEdit = true,
      hasOperator = false,
      uppercaseTokenName = false,
      capitalizeTokenValue = false,
    } = options;

    return `
      <div class="${canEdit ? 'selectable' : 'hidden'}" role="button">
        <div class="${uppercaseTokenName ? 'text-uppercase' : ''} name"></div>
        ${hasOperator ? '<div class="operator"></div>' : ''}
        <div class="value-container">
          <div class="${capitalizeTokenValue ? 'text-capitalize' : ''} value"></div>
          <div class="remove-token" role="button">
            ${spriteIcon('close', 's16 close-icon')}
          </div>
        </div>
      </div>
    `;
  }

  static renderVisualTokenValue(parentElement, tokenName, tokenValue, tokenOperator) {
    const tokenType = tokenName.toLowerCase();
    const tokenValueContainer = parentElement.querySelector('.value-container');
    const tokenValueElement = tokenValueContainer.querySelector('.value');
    tokenValueElement.textContent = tokenValue;

    const visualTokenValue = new VisualTokenValue(tokenValue, tokenType, tokenOperator);

    visualTokenValue.render(tokenValueContainer, tokenValueElement);
  }

  static addVisualTokenElement({ name, operator, value, options = {} }) {
    const {
      isSearchTerm = false,
      canEdit,
      uppercaseTokenName,
      capitalizeTokenValue,
      tokenClass = `search-token-${name.toLowerCase()}`,
    } = options;
    const li = document.createElement('li');
    li.classList.add('js-visual-token');
    li.classList.add(isSearchTerm ? 'filtered-search-term' : 'filtered-search-token');

    if (!isSearchTerm) {
      li.classList.add(tokenClass);
    }

    const hasOperator = Boolean(operator);

    if (value) {
      li.innerHTML = FilteredSearchVisualTokens.createVisualTokenElementHTML({
        canEdit,
        uppercaseTokenName,
        operator,
        hasOperator,
        capitalizeTokenValue,
      });
      FilteredSearchVisualTokens.renderVisualTokenValue(li, name, value, operator);
    } else {
      const nameHTML = `<div class="${uppercaseTokenName ? 'text-uppercase' : ''} name"></div>`;
      let operatorHTML = '';

      if (hasOperator) {
        operatorHTML = '<div class="operator"></div>';
      }

      li.innerHTML = nameHTML + operatorHTML;
    }

    li.querySelector('.name').textContent = name;
    if (hasOperator) {
      li.querySelector('.operator').textContent = operator;
    }

    const tokensContainer = FilteredSearchContainer.container.querySelector('.tokens-container');
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');
    tokensContainer.insertBefore(li, input.parentElement);
  }

  static addValueToPreviousVisualTokenElement(value) {
    const {
      lastVisualToken,
      isLastVisualTokenValid,
    } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (!isLastVisualTokenValid && lastVisualToken.classList.contains('filtered-search-token')) {
      const name = FilteredSearchVisualTokens.getLastTokenPartial();
      const operator = FilteredSearchVisualTokens.getLastTokenOperator();
      lastVisualToken.innerHTML = FilteredSearchVisualTokens.createVisualTokenElementHTML({
        hasOperator: Boolean(operator),
      });
      lastVisualToken.querySelector('.name').textContent = name;
      lastVisualToken.querySelector('.operator').textContent = operator;
      FilteredSearchVisualTokens.renderVisualTokenValue(lastVisualToken, name, value, operator);
    }
  }

  static addFilterVisualToken(
    tokenName,
    tokenOperator,
    tokenValue,
    { canEdit, uppercaseTokenName = false, capitalizeTokenValue = false } = {},
  ) {
    const {
      lastVisualToken,
      isLastVisualTokenValid,
    } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();
    const { addVisualTokenElement } = FilteredSearchVisualTokens;

    if (isLastVisualTokenValid) {
      addVisualTokenElement({
        name: tokenName,
        operator: tokenOperator,
        value: tokenValue,
        options: {
          canEdit,
          uppercaseTokenName,
          capitalizeTokenValue,
        },
      });
    } else if (
      !isLastVisualTokenValid &&
      lastVisualToken &&
      !lastVisualToken.querySelector('.operator')
    ) {
      const tokensContainer = FilteredSearchContainer.container.querySelector('.tokens-container');
      tokensContainer.removeChild(lastVisualToken);
      addVisualTokenElement({
        name: tokenName,
        operator: tokenOperator,
        value: tokenValue,
        options: {
          canEdit,
          uppercaseTokenName,
          capitalizeTokenValue,
        },
      });
    } else {
      const previousTokenName = lastVisualToken.querySelector('.name').textContent;
      const previousTokenOperator = lastVisualToken.querySelector('.operator').textContent;
      const tokensContainer = FilteredSearchContainer.container.querySelector('.tokens-container');
      tokensContainer.removeChild(lastVisualToken);

      let value = tokenValue;
      if (!value && !tokenOperator) {
        value = tokenName;
      }
      addVisualTokenElement({
        name: previousTokenName,
        operator: previousTokenOperator,
        value,
        options: {
          canEdit,
          uppercaseTokenName,
          capitalizeTokenValue,
        },
      });
    }
  }

  static addSearchVisualToken(searchTerm) {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (lastVisualToken && lastVisualToken.classList.contains('filtered-search-term')) {
      lastVisualToken.querySelector('.name').textContent += ` ${searchTerm}`;
    } else {
      FilteredSearchVisualTokens.addVisualTokenElement({
        name: searchTerm,
        operator: null,
        value: null,
        options: {
          isSearchTerm: true,
        },
      });
    }
  }

  static getLastTokenPartial(includeOperator = false) {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (!lastVisualToken) return '';

    const valueContainer = lastVisualToken.querySelector('.value-container');
    const originalValue = valueContainer && valueContainer.dataset.originalValue;
    if (originalValue) {
      return originalValue;
    }

    const value = lastVisualToken.querySelector('.value');
    const name = lastVisualToken.querySelector('.name');

    const valueText = value ? value.textContent : '';
    const nameText = name ? name.textContent : '';

    if (includeOperator) {
      const operator = lastVisualToken.querySelector('.operator');
      const operatorText = operator ? operator.textContent : '';
      return valueText || operatorText || nameText;
    }

    return valueText || nameText;
  }

  static getLastTokenOperator() {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    const operator = lastVisualToken && lastVisualToken.querySelector('.operator');

    return operator?.textContent;
  }

  static removeLastTokenPartial() {
    const { lastVisualToken } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (lastVisualToken) {
      const value = lastVisualToken.querySelector('.value');
      const operator = lastVisualToken.querySelector('.operator');
      if (value) {
        const button = lastVisualToken.querySelector('.selectable');
        const valueContainer = lastVisualToken.querySelector('.value-container');
        button.removeChild(valueContainer);
        lastVisualToken.innerHTML = button.innerHTML;
      } else if (operator) {
        lastVisualToken.removeChild(operator);
      } else {
        lastVisualToken.closest('.tokens-container').removeChild(lastVisualToken);
      }
    }
  }

  static tokenizeInput() {
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');
    const { isLastVisualTokenValid } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

    if (input.value) {
      if (isLastVisualTokenValid) {
        FilteredSearchVisualTokens.addSearchVisualToken(input.value);
      } else {
        FilteredSearchVisualTokens.addValueToPreviousVisualTokenElement(input.value);
      }

      input.value = '';
    }
  }

  /**
   * Returns a computed API endpoint
   * and query string composed of values from endpointQueryParams
   * @param {String} endpoint
   * @param {String} endpointQueryParams
   */
  static getEndpointWithQueryParams(endpoint, endpointQueryParams) {
    if (!endpointQueryParams) {
      return endpoint;
    }

    const queryString = objectToQuery(JSON.parse(endpointQueryParams));
    return `${endpoint}?${queryString}`;
  }

  static editToken(token) {
    const input = FilteredSearchContainer.container.querySelector('.filtered-search');

    FilteredSearchVisualTokens.tokenizeInput();

    // Replace token with input field
    const tokenContainer = token.parentElement;
    const inputLi = input.parentElement;
    tokenContainer.replaceChild(inputLi, token);

    const nameElement = token.querySelector('.name');
    const operatorElement = token.querySelector('.operator');
    let value;

    if (token.classList.contains('filtered-search-token')) {
      FilteredSearchVisualTokens.addFilterVisualToken(
        nameElement.textContent,
        operatorElement.textContent,
        null,
        {
          uppercaseTokenName: nameElement.classList.contains('text-uppercase'),
        },
      );

      const valueContainerElement = token.querySelector('.value-container');
      value = valueContainerElement.dataset.originalValue;

      if (!value) {
        const valueElement = valueContainerElement.querySelector('.value');
        value = valueElement.textContent;
      }
    }

    // token is a search term
    if (!value) {
      value = nameElement.textContent;
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
      const { isLastVisualTokenValid } = FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

      if (!isLastVisualTokenValid) {
        const lastPartial = FilteredSearchVisualTokens.getLastTokenPartial();
        FilteredSearchVisualTokens.removeLastTokenPartial();
        FilteredSearchVisualTokens.addSearchVisualToken(lastPartial);
      }

      tokenContainer.removeChild(inputLi);
      tokenContainer.appendChild(inputLi);
    }
  }
}
