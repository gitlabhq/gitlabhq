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
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);
      const valueWithoutColon = value.slice(1).toLowerCase();
      const prefix = valueWithoutColon[0];
      const valueWithoutPrefix = valueWithoutColon.slice(1);

      const title = updatedItem.title.toLowerCase();

      // Eg. filterSymbol = ~ for labels
      const matchWithoutPrefix =
        prefix === filterSymbol && title.indexOf(valueWithoutPrefix) !== -1;
      const match = title.indexOf(valueWithoutColon) !== -1;

      updatedItem.droplab_hidden = !match && !matchWithoutPrefix;
      return updatedItem;
    }

    static filterMethod(item, query) {
      const updatedItem = item;
      const { value } = gl.FilteredSearchTokenizer.getLastTokenObject(query);

      if (value === '') {
        updatedItem.droplab_hidden = false;
      } else {
        updatedItem.droplab_hidden = updatedItem.hint.indexOf(value) === -1;
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
