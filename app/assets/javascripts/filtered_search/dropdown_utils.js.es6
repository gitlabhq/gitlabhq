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

    static filterWithSymbol(filterSymbol, item, query) {
      const updatedItem = item;
      const { lastToken, searchToken } = gl.FilteredSearchTokenizer.processTokens(query);

      if (lastToken !== searchToken) {
        const value = lastToken.value.toLowerCase();
        const title = updatedItem.title.toLowerCase();

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
      const { lastToken } = gl.FilteredSearchTokenizer.processTokens(query);

      if (!lastToken) {
        updatedItem.droplab_hidden = false;
      } else {
        updatedItem.droplab_hidden = updatedItem.hint.indexOf(lastToken.toLowerCase()) === -1;
      }

      return updatedItem;
    }

    static setDataValueIfSelected(selected) {
      const dataValue = selected.getAttribute('data-value');

      if (dataValue) {
        gl.FilteredSearchDropdownManager.addWordToInput(dataValue);
      }

      // Return boolean based on whether it was set
      return dataValue !== null;
    }
  }

  window.gl = window.gl || {};
  gl.DropdownUtils = DropdownUtils;
})();
