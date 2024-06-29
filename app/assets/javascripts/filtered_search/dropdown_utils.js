import { last } from 'lodash';
import { TOKEN_TYPE_LABEL } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchContainer from './container';
import FilteredSearchDropdownManager from './filtered_search_dropdown_manager';
import FilteredSearchTokenizer from './filtered_search_tokenizer';
import FilteredSearchVisualTokens from './filtered_search_visual_tokens';

export default class DropdownUtils {
  static getEscapedText(text) {
    let escapedText = text;
    const hasSpace = text.indexOf(' ') !== -1;
    const hasDoubleQuote = text.indexOf('"') !== -1;

    // Encapsulate value with quotes if it has spaces
    // Known side effect: values's with both single and double quotes
    // won't escape properly
    if (hasSpace) {
      if (hasDoubleQuote) {
        escapedText = `'${text}'`;
      } else {
        // Encapsulate singleQuotes or if it hasSpace
        escapedText = `"${text}"`;
      }
    }

    return escapedText;
  }

  static filterWithSymbol(filterSymbol, input, item) {
    const updatedItem = item;
    const searchInput = DropdownUtils.getSearchInput(input);

    const title = updatedItem.title.toLowerCase();
    let value = searchInput.toLowerCase();
    let symbol = '';

    // Remove the symbol for filter
    if (value[0] === filterSymbol) {
      [symbol] = value;
      value = value.slice(1);
    }

    // Removes the first character if it is a quotation so that we can search
    // with multiple words
    if ((value[0] === '"' || value[0] === "'") && title.indexOf(' ') !== -1) {
      value = value.slice(1);
    }

    // Eg. filterSymbol = ~ for labels
    const matchWithoutSymbol = symbol === filterSymbol && title.indexOf(value) !== -1;
    const match = title.indexOf(`${symbol}${value}`) !== -1;

    updatedItem.droplab_hidden = !match && !matchWithoutSymbol;

    return updatedItem;
  }

  static filterHint(config, item) {
    const { input, allowedKeys } = config;
    const updatedItem = item;
    const searchInput = DropdownUtils.getSearchQuery(input);
    const { lastToken, tokens } = FilteredSearchTokenizer.processTokens(searchInput, allowedKeys);
    const lastKey = lastToken.key || lastToken || '';
    const allowMultiple = item.type === 'array';
    const itemInExistingTokens = tokens.some((t) => t.key === item.hint);
    const isSearchItem = updatedItem.hint === 'search';

    if (isSearchItem) {
      updatedItem.droplab_hidden = true;
    }

    if (!allowMultiple && itemInExistingTokens) {
      updatedItem.droplab_hidden = true;
    } else if (!isSearchItem && (!lastKey || last(searchInput.split('')) === ' ')) {
      updatedItem.droplab_hidden = false;
    } else if (lastKey) {
      const split = lastKey.split(':');
      const tokenName = last(split[0].split(' '));

      const match = isSearchItem
        ? allowedKeys.some((key) => key.startsWith(tokenName.toLowerCase()))
        : updatedItem.hint.indexOf(tokenName.toLowerCase()) === -1;

      updatedItem.droplab_hidden = tokenName ? match : false;
    }

    return updatedItem;
  }

  static setDataValueIfSelected(filter, operator, selected) {
    // eslint-disable-next-line unicorn/prefer-dom-node-dataset
    const dataValue = selected.getAttribute('data-value');

    if (dataValue) {
      FilteredSearchDropdownManager.addWordToInput({
        tokenName: filter,
        tokenOperator: operator,
        tokenValue: dataValue,
        clicked: true,
        options: {
          // eslint-disable-next-line unicorn/prefer-dom-node-dataset
          capitalizeTokenValue: selected.hasAttribute('data-capitalize'),
        },
      });
    }

    // Return boolean based on whether it was set
    return dataValue !== null;
  }

  static getVisualTokenValues(visualToken) {
    const tokenName = visualToken && visualToken.querySelector('.name').textContent.trim();
    let tokenValue =
      visualToken &&
      visualToken.querySelector('.value') &&
      visualToken.querySelector('.value').textContent.trim();
    if (tokenName === TOKEN_TYPE_LABEL && tokenValue) {
      // remove leading symbol and wrapping quotes
      tokenValue = tokenValue.replace(/^~("|')?(.*)/, '$2').replace(/("|')$/, '');
    }

    const operatorEl = visualToken && visualToken.querySelector('.operator');
    const tokenOperator = operatorEl && operatorEl.textContent.trim();

    return { tokenName, tokenOperator, tokenValue };
  }

  // Determines the full search query (visual tokens + input)
  static getSearchQuery(untilInput = false) {
    const { container } = FilteredSearchContainer;
    const tokens = [].slice.call(container.querySelectorAll('.tokens-container li'));
    const values = [];

    if (untilInput) {
      const inputIndex = tokens.findIndex((t) => t.classList.contains('input-token'));
      // Add one to include input-token to the tokens array
      tokens.splice(inputIndex + 1);
    }

    tokens.forEach((token) => {
      if (token.classList.contains('js-visual-token')) {
        const name = token.querySelector('.name');
        const operatorContainer = token.querySelector('.operator');
        const value = token.querySelector('.value');
        const valueContainer = token.querySelector('.value-container');
        const symbol = value && value.dataset.symbol ? value.dataset.symbol : '';
        let valueText = '';
        let operator = '';

        if (operatorContainer) {
          operator = operatorContainer.textContent.trim();
        }

        if (valueContainer && valueContainer.dataset.originalValue) {
          valueText = valueContainer.dataset.originalValue;
        } else if (value && value.innerText) {
          valueText = value.innerText;
        }

        if (token.className.indexOf('filtered-search-token') !== -1) {
          values.push(`${name.innerText.toLowerCase()}:${operator}${symbol}${valueText}`);
        } else {
          values.push(name.innerText);
        }
      } else if (token.classList.contains('input-token')) {
        const { isLastVisualTokenValid } =
          FilteredSearchVisualTokens.getLastVisualTokenBeforeInput();

        const input = FilteredSearchContainer.container.querySelector('.filtered-search');
        const inputValue = input && input.value;

        if (isLastVisualTokenValid) {
          values.push(inputValue);
        } else {
          const previous = values.pop();
          values.push(`${previous}${inputValue}`);
        }
      }
    });

    return values.map((value) => value.trim()).join(' ');
  }

  static getSearchInput(filteredSearchInput) {
    const inputValue = filteredSearchInput.value;
    const { right } = DropdownUtils.getInputSelectionPosition(filteredSearchInput);

    return inputValue.slice(0, right);
  }

  static getInputSelectionPosition(input) {
    const { selectionStart } = input;
    let inputValue = input.value;
    // Replace all spaces inside quote marks with underscores
    // (will continue to match entire string until an end quote is found if any)
    // This helps with matching the beginning & end of a token:key
    inputValue = inputValue.replace(/(('[^']*'{0,1})|("[^"]*"{0,1})|:\s+)/g, (str) =>
      str.replace(/\s/g, '_'),
    );

    // Get the right position for the word selected
    // Regex matches first space
    let right = inputValue.slice(selectionStart).search(/\s/);

    if (right >= 0) {
      right += selectionStart;
    } else if (right < 0) {
      right = inputValue.length;
    }

    // Get the left position for the word selected
    // Regex matches last non-whitespace character
    let left = inputValue.slice(0, right).search(/\S+$/);

    if (selectionStart === 0) {
      left = 0;
    } else if (selectionStart === inputValue.length && left < 0) {
      left = inputValue.length;
    } else if (left < 0) {
      left = selectionStart;
    }

    return {
      left,
      right,
    };
  }
}
