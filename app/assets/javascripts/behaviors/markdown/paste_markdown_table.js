const maxColumnWidth = (rows, columnIndex) =>
  Math.max(...rows.map((row) => row[columnIndex].length));

export default class PasteMarkdownTable {
  constructor(clipboardData) {
    this.data = clipboardData;
    this.columnWidths = [];
    this.rows = [];
    this.tableFound = this.parseTable();
  }

  isTable() {
    return this.tableFound;
  }

  convertToTableMarkdown() {
    this.calculateColumnWidths();

    const markdownRows = this.rows.map(
      (row) =>
        // | Name         | Title | Email Address  |
        // |--------------|-------|----------------|
        // | Jane Atler   | CEO   | jane@acme.com  |
        // | John Doherty | CTO   | john@acme.com  |
        // | Sally Smith  | CFO   | sally@acme.com |
        `| ${row.map((column, index) => this.formatColumn(column, index)).join(' | ')} |`,
    );

    // Insert a header break (e.g. -----) to the second row
    markdownRows.splice(1, 0, this.generateHeaderBreak());

    return markdownRows.join('\n');
  }

  // Private methods below

  // To determine whether the cut data is a table, the following criteria
  // must be satisfied with the clipboard data:
  //
  // 1. MIME types "text/plain" and "text/html" exist
  // 2. The "text/html" data must have a single <table> element
  // 3. The number of rows in the "text/plain" data matches that of the "text/html" data
  // 4. The max number of columns in "text/plain" matches that of the "text/html" data
  parseTable() {
    if (!this.data.types.includes('text/html') || !this.data.types.includes('text/plain')) {
      return false;
    }

    const htmlData = this.data.getData('text/html');
    this.doc = new DOMParser().parseFromString(htmlData, 'text/html');
    // Avoid formatting lines that were copied from a diff
    const tables = this.doc.querySelectorAll('table:not(.diff-wrap-lines)');

    // We're only looking for exactly one table. If there happens to be
    // multiple tables, it's possible an application copied data into
    // the clipboard that is not related to a simple table. It may also be
    // complicated converting multiple tables into Markdown.
    if (tables.length !== 1) {
      return false;
    }

    const text = this.data.getData('text/plain').trim();
    const splitRows = text.split(/[\n\u0085\u2028\u2029]|\r\n?/g);

    // Now check that the number of rows matches between HTML and text
    if (this.doc.querySelectorAll('tr').length !== splitRows.length) {
      return false;
    }

    this.rows = splitRows.map((row) => row.split('\t'));
    this.normalizeRows();

    // Check that the max number of columns in the HTML matches the number of
    // columns in the text. GitHub, for example, copies a line number and the
    // line itself into the HTML data.
    if (!this.columnCountsMatch()) {
      return false;
    }

    return true;
  }

  // Ensure each row has the same number of columns
  normalizeRows() {
    const rowLengths = this.rows.map((row) => row.length);
    const maxLength = Math.max(...rowLengths);

    this.rows.forEach((row) => {
      while (row.length < maxLength) {
        row.push('');
      }
    });
  }

  calculateColumnWidths() {
    this.columnWidths = this.rows[0].map((_column, columnIndex) =>
      maxColumnWidth(this.rows, columnIndex),
    );
  }

  columnCountsMatch() {
    const textColumnCount = this.rows[0].length;
    let htmlColumnCount = 0;

    this.doc.querySelectorAll('table tr').forEach((row) => {
      htmlColumnCount = Math.max(row.cells.length, htmlColumnCount);
    });

    return textColumnCount === htmlColumnCount;
  }

  formatColumn(column, index) {
    const spaces = Array(this.columnWidths[index] - column.length + 1).join(' ');
    return column + spaces;
  }

  generateHeaderBreak() {
    // Add 3 dashes to line things up: there is additional spacing for the pipe characters
    const dashes = this.columnWidths.map((width, index) =>
      Array(this.columnWidths[index] + 3).join('-'),
    );
    return `|${dashes.join('|')}|`;
  }
}
