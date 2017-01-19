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
      const query = gl.DropdownUtils.getSearchInput(input).trim();
      const { lastToken, searchToken } = gl.FilteredSearchTokenizer.processTokens(query);

      if (lastToken !== searchToken) {
        const title = updatedItem.title.toLowerCase();
        let value = lastToken.value.toLowerCase();

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

    static filterHint(item, query) {
      const updatedItem = item;
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
      const selectionStart = filteredSearchInput.selectionStart;
      const inputValue = filteredSearchInput.value;
      const { right } = gl.DropdownUtils.getInputSelectionPosition(filteredSearchInput);

      if (right < 0) {
        return inputValue;
      }

      return inputValue.slice(0, right + selectionStart + 1).trim();
    }

    static getInputSelectionPosition(input) {
      const inputValue = input.value;
      const selectionStart = input.selectionStart;
      const left = inputValue.slice(0, selectionStart + 1).search(/\S+$/);
      const right = inputValue.slice(selectionStart).search(/\s/);

      return {
        left,
        right,
      };
    }
  }

  window.gl = window.gl || {};
  gl.DropdownUtils = DropdownUtils;
})();
