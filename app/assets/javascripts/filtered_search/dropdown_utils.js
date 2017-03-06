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
      const query = gl.DropdownUtils.getSearchInput(input);
      const { lastToken, searchToken } = gl.FilteredSearchTokenizer.processTokens(query);

      if (lastToken !== searchToken) {
        const title = updatedItem.title.toLowerCase();
        let value = lastToken.value.toLowerCase();

        // Removes the first character if it is a quotation so that we can search
        // with multiple words
        if ((value[0] === '"' || value[0] === '\'') && title.indexOf(' ') !== -1) {
          value = value.slice(1);
        }

        // Eg. filterSymbol = ~ for labels
        const matchWithoutSymbol = lastToken.symbol === filterSymbol && title.indexOf(value) !== -1;
        const match = title.indexOf(`${lastToken.symbol}${value}`) !== -1;

        updatedItem.droplab_hidden = !match && !matchWithoutSymbol;
      } else {
        updatedItem.droplab_hidden = false;
      }

      return updatedItem;
    }

    static filterHint(input, item) {
      const updatedItem = item;
      const query = gl.DropdownUtils.getSearchInput(input);
      let { lastToken } = gl.FilteredSearchTokenizer.processTokens(query);
      lastToken = lastToken.key || lastToken || '';

      if (!lastToken || query.split('').last() === ' ') {
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
        gl.FilteredSearchDropdownManager.addWordToInput(filter, dataValue);
      }

      // Return boolean based on whether it was set
      return dataValue !== null;
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
