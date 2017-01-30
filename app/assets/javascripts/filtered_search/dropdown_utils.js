(() => {
  class DropdownUtils {
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
      const searchInput = gl.DropdownUtils.getSearchInput(input);

      const title = updatedItem.title.toLowerCase();
      let value = searchInput.toLowerCase();
      let symbol = '';

      // Remove the symbol for filter
      if (value[0] === filterSymbol) {
        symbol = value[0];
        value = value.slice(1);
      }

      // Removes the first character if it is a quotation so that we can search
      // with multiple words
      if ((value[0] === '"' || value[0] === '\'') && title.indexOf(' ') !== -1) {
        value = value.slice(1);
      }

      // Eg. filterSymbol = ~ for labels
      const matchWithoutSymbol = symbol === filterSymbol && title.indexOf(value) !== -1;
      const match = title.indexOf(`${symbol}${value}`) !== -1;

      updatedItem.droplab_hidden = !match && !matchWithoutSymbol;

      return updatedItem;
    }

    static filterHint(input, item) {
      const updatedItem = item;
      const searchInput = gl.DropdownUtils.getSearchInput(input);
      let { lastToken } = gl.FilteredSearchTokenizer.processTokens(searchInput);
      lastToken = lastToken.key || lastToken || '';

      if (!lastToken || searchInput.split('').last() === ' ') {
        updatedItem.droplab_hidden = false;
      } else if (lastToken) {
        const split = lastToken.split(':');
        const tokenName = split[0].split(' ').last();

        const match = updatedItem.hint.indexOf(tokenName.toLowerCase()) === -1;
        updatedItem.droplab_hidden = tokenName ? match : false;
      }

      return updatedItem;
    }

    static setDataValueIfSelected(filter, selected) {
      const dataValue = selected.getAttribute('data-value');

      if (dataValue) {
        gl.FilteredSearchDropdownManager.addWordToInput(filter, dataValue, true);
      }

      // Return boolean based on whether it was set
      return dataValue !== null;
    }

    static getSearchQuery() {
      const tokensContainer = document.querySelector('.tokens-container');
      const values = [];

      [].forEach.call(tokensContainer.querySelectorAll('.js-visual-token'), (token) => {
        const name = token.querySelector('.name');
        const value = token.querySelector('.value');
        const symbol = value && value.dataset.symbol ? value.dataset.symbol : '';
        let valueText = '';

        if (value && value.innerText) {
          valueText = value.innerText;
        }

        if (token.className.indexOf('filtered-search-token') !== -1) {
          values.push(`${name.innerText.toLowerCase()}:${symbol}${valueText}`);
        } else {
          values.push(name.innerText);
        }
      });

      const input = document.querySelector('.filtered-search');
      values.push(input && input.value);

      return values.join(' ');
    }

    static getSearchInput(filteredSearchInput) {
      const inputValue = filteredSearchInput.value;
      const { right } = gl.DropdownUtils.getInputSelectionPosition(filteredSearchInput);

      return inputValue.slice(0, right);
    }

    static getInputSelectionPosition(input) {
      const selectionStart = input.selectionStart;
      let inputValue = input.value;
      // Replace all spaces inside quote marks with underscores
      // (will continue to match entire string until an end quote is found if any)
      // This helps with matching the beginning & end of a token:key
      inputValue = inputValue.replace(/(('[^']*'{0,1})|("[^"]*"{0,1})|:\s+)/g, str => str.replace(/\s/g, '_'));

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

  window.gl = window.gl || {};
  gl.DropdownUtils = DropdownUtils;
})();
