export class DiffLineRow {
  constructor(row) {
    this.row = row;
  }

  #getLineNumber(position) {
    const { lineNumber } = this.row.querySelector(
      `[data-position="${position}"] [data-line-number]`,
    ).dataset;
    return parseInt(lineNumber, 10);
  }

  get oldLineNumber() {
    return this.#getLineNumber('old');
  }

  get newLineNumber() {
    return this.#getLineNumber('new');
  }
}
