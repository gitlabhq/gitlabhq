export default class PasteMarkdownTable {
  constructor(clipboardData) {
    this.data = clipboardData;
  }

  static maxColumnWidth(rows, columnIndex) {
    return Math.max.apply(null, rows.map(row => row[columnIndex].length));
  }

  // To determine whether the cut data is a table, the following criteria
  // must be satisfied with the clipboard data:
  //
  // 1. MIME types "text/plain" and "text/html" exist
  // 2. The "text/html" data must have a single <table> element
  static isTable(data) {
    const types = new Set(data.types);

    if (!types.has('text/html') || !types.has('text/plain')) {
      return false;
    }

    const htmlData = data.getData('text/html');
    const doc = new DOMParser().parseFromString(htmlData, 'text/html');

    // We're only looking for exactly one table. If there happens to be
    // multiple tables, it's possible an application copied data into
    // the clipboard that is not related to a simple table. It may also be
    // complicated converting multiple tables into Markdown.
    if (doc.querySelectorAll('table').length === 1) {
      return true;
    }

    return false;
  }

  convertToTableMarkdown() {
    const text = this.data.getData('text/plain').trim();
    this.rows = text.split(/[\n\u0085\u2028\u2029]|\r\n?/g).map(row => row.split('\t'));
    this.normalizeRows();
    this.calculateColumnWidths();

    const markdownRows = this.rows.map(
      row =>
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

  // Ensure each row has the same number of columns
  normalizeRows() {
    const rowLengths = this.rows.map(row => row.length);
    const maxLength = Math.max(...rowLengths);

    this.rows.forEach(row => {
      while (row.length < maxLength) {
        row.push('');
      }
    });
  }

  calculateColumnWidths() {
    this.columnWidths = this.rows[0].map((_column, columnIndex) =>
      PasteMarkdownTable.maxColumnWidth(this.rows, columnIndex),
    );
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
