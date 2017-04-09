import xlsx from 'xlsx'

export default class XlsxViewer {
  constructor(el) {
    this.el = el;
    this.loadXlsxFile();
  }

  loadXlsxFile() {
    var self = this;
    var url = this.el.dataset.endpoint;
    var oReq = new XMLHttpRequest();
    oReq.open("GET", url, true);
    oReq.responseType = "arraybuffer";

    oReq.onload = function(e) {
      var arraybuffer = oReq.response;

      /* convert data to binary string */
      var data = new Uint8Array(arraybuffer);
      var arr = new Array();
      for(var i = 0; i != data.length; ++i) arr[i] = String.fromCharCode(data[i]);
      var bstr = arr.join("");

      /* Call XLSX */
      var workbook = xlsx.read(bstr, {type:"binary"});
      self.processWorkbook(workbook);
    }

    oReq.send();
  }


  getColumns(sheet, type) {
    var val, rowObject, range, columnHeaders, emptyRow, C;
    if(!sheet['!ref']) return [];
    range = xlsx.utils.decode_range(sheet["!ref"]);
    columnHeaders = [];
    for (C = range.s.c; C <= range.e.c; ++C) {
      val = sheet[xlsx.utils.encode_cell({c: C, r: range.s.r})];
      if(!val) continue;
      columnHeaders[C] = val.v;
    }
    return columnHeaders;
  }

  toJson(wb) {
    var result = {};
    wb.SheetNames.forEach(function(sheetName) {
      var roa = xlsx.utils.sheet_to_row_object_array(wb.Sheets[sheetName], {raw:true});
      if(roa.length > 0) result[sheetName] = roa;
    });
    return result;
  }

  chooseSheet(sheetidx) {
    this.processWorkbook(last_wb, sheetidx);
  }

  processWorkbook(wb, sheetidx) {
    // opts.on.wb(wb, sheetidx);
    var sheet = wb.SheetNames[sheetidx || 1];
    var json = this.toJson(wb)[sheet], cols = this.getColumns(wb.Sheets[sheet]);
    // opts.on.sheet(json, cols, wb.SheetNames, chooseSheet);
    console.log(sheet)
    console.log(json)
  }
}