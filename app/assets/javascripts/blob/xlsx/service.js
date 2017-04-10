/* eslint-disable class-methods-use-this */
import xlsx from 'xlsx';

export default class XlsxService {
  constructor(endpoint) {
    this.endpoint = endpoint;
  }

  getData() {
    return this.loadFile()
      .then(workbook => this.processWorkbook(workbook));
  }

  loadFile() {
    return new Promise((resolve) => {
      const request = new XMLHttpRequest();
      request.open('GET', this.endpoint, true);
      request.responseType = 'arraybuffer';

      request.onload = () => {
        const arraybuffer = request.response;
        const data = new Uint8Array(arraybuffer);
        const arr = [];
        data.forEach((d) => {
          arr.push(String.fromCharCode(d));
        });
        const bstr = arr.join('');
        const workbook = xlsx.read(bstr, {
          type: 'binary',
        });

        resolve(workbook);
      };

      request.send();
    });
  }

  processWorkbook(workbook) {
    return new Promise((resolve) => {
      const sheets = workbook.Sheets;
      const data = {};

      workbook.SheetNames.forEach((sheetName) => {
        const sheet = sheets[sheetName];
        const columns = this.getColumns(sheet);
        const rows = xlsx.utils.sheet_to_json(sheet, {
          raw: true,
        }).map((row) => {
          const arr = [];

          columns.forEach((col) => {
            const val = row[col];

            if (typeof val !== 'undefined') {
              arr.push(val);
            } else {
              arr.push('');
            }
          });

          return arr;
        });

        data[sheetName] = {
          columns,
          rows,
        };
      });

      resolve(data);
    });
  }

  getColumns(sheet) {
    if (!sheet['!ref']) return [];

    const range = xlsx.utils.decode_range(sheet['!ref']);
    const columnHeaders = [];
    for (let c = range.s.c; c <= range.e.c; c += 1) {
      const val = sheet[xlsx.utils.encode_cell({
        c,
        r: range.s.r,
      })];

      if (val) {
        columnHeaders.push(val.v);
      }
    }
    return columnHeaders;
  }
}
