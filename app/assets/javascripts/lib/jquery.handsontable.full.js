/**
 * Handsontable 0.8.3
 * Handsontable is a simple jQuery plugin for editable tables with basic copy-paste compatibility with Excel and Google Docs
 *
 * Copyright 2012, Marcin Warpechowski
 * Licensed under the MIT license.
 * http://handsontable.com/
 *
 * Date: Wed Jan 23 2013 03:09:58 GMT+0100 (Central European Standard Time)
 */
/*jslint white: true, browser: true, plusplus: true, indent: 4, maxerr: 50 */

var Handsontable = { //class namespace
  extension: {}, //extenstion namespace
  helper: {} //helper namespace
};

(function ($, window, Handsontable) {
  "use strict";
/**
 * Handsontable constructor
 * @param rootElement The jQuery element in which Handsontable DOM will be inserted
 * @param settings
 * @constructor
 */
Handsontable.Core = function (rootElement, settings) {
  this.rootElement = rootElement;

  var priv, datamap, grid, selection, editproxy, autofill, validate, self = this;

  priv = {
    settings: {},
    selStart: (new Handsontable.SelectionPoint()),
    selEnd: (new Handsontable.SelectionPoint()),
    editProxy: false,
    isPopulated: null,
    scrollable: null,
    undoRedo: null,
    extensions: {},
    colToProp: null,
    propToCol: null,
    dataSchema: null,
    dataType: 'array',
    firstRun: true
  };

  datamap = {
    recursiveDuckSchema: function (obj) {
      var schema;
      if ($.isPlainObject(obj)) {
        schema = {};
        for (var i in obj) {
          if (obj.hasOwnProperty(i)) {
            if ($.isPlainObject(obj[i])) {
              schema[i] = datamap.recursiveDuckSchema(obj[i]);
            }
            else {
              schema[i] = null;
            }
          }
        }
      }
      else {
        schema = [];
      }
      return schema;
    },

    recursiveDuckColumns: function (schema, lastCol, parent) {
      var prop, i;
      if (typeof lastCol === 'undefined') {
        lastCol = 0;
        parent = '';
      }
      if ($.isPlainObject(schema)) {
        for (i in schema) {
          if (schema.hasOwnProperty(i)) {
            if (schema[i] === null) {
              prop = parent + i;
              priv.colToProp.push(prop);
              priv.propToCol[prop] = lastCol;
              lastCol++;
            }
            else {
              lastCol = datamap.recursiveDuckColumns(schema[i], lastCol, i + '.');
            }
          }
        }
      }
      return lastCol;
    },

    createMap: function () {
      if (typeof datamap.getSchema() === "undefined") {
        throw new Error("trying to create `columns` definition but you didnt' provide `schema` nor `data`");
      }
      var i, ilen, schema = datamap.getSchema();
      priv.colToProp = [];
      priv.propToCol = {};
      if (priv.settings.columns) {
        for (i = 0, ilen = priv.settings.columns.length; i < ilen; i++) {
          priv.colToProp[i] = priv.settings.columns[i].data;
          priv.propToCol[priv.settings.columns[i].data] = i;
        }
      }
      else {
        datamap.recursiveDuckColumns(schema);
      }
    },

    colToProp: function (col) {
      col = Handsontable.PluginModifiers.run(self, 'col', col);
      if (priv.colToProp && typeof priv.colToProp[col] !== 'undefined') {
        return priv.colToProp[col];
      }
      else {
        return col;
      }
    },

    propToCol: function (prop) {
      var col;
      if (typeof priv.propToCol[prop] !== 'undefined') {
        col = priv.propToCol[prop];
      }
      else {
        col = prop;
      }
      col = Handsontable.PluginModifiers.run(self, 'col', col);
      return col;
    },

    getSchema: function () {
      if (priv.settings.dataSchema) {
        if (typeof priv.settings.dataSchema === 'function') {
          return priv.settings.dataSchema();
        }
        return priv.settings.dataSchema;
      }
      return priv.duckDataSchema;
    },

    /**
     * Creates row at the bottom of the data array
     * @param {Object} [coords] Optional. Coords of the cell before which the new row will be inserted
     */
    createRow: function (coords) {
      var row;
      if (priv.dataType === 'array') {
        row = [];
        for (var c = 0, clen = self.countCols(); c < clen; c++) {
          row.push(null);
        }
      }
      else {
        row = $.extend(true, {}, datamap.getSchema());
      }
      if (!coords || coords.row >= self.countRows()) {
        if (priv.settings.onCreateRow) {
          priv.settings.onCreateRow(self.countRows(), row);
        }
        priv.settings.data.push(row);
      }
      else {
        if (priv.settings.onCreateRow) {
          priv.settings.onCreateRow(coords.row, row);
        }
        priv.settings.data.splice(coords.row, 0, row);
      }
      self.forceFullRender = true; //used when data was changed
    },

    /**
     * Creates col at the right of the data array
     * @param {Object} [coords] Optional. Coords of the cell before which the new column will be inserted
     */
    createCol: function (coords) {
      if (priv.dataType === 'object' || priv.settings.columns) {
        throw new Error("Cannot create new column. When data source in an object, you can only have as much columns as defined in first data row, data schema or in the 'columns' setting");
      }
      var r = 0, rlen = self.countRows();
      if (!coords || coords.col >= self.countCols()) {
        for (; r < rlen; r++) {
          if (typeof priv.settings.data[r] === 'undefined') {
            priv.settings.data[r] = [];
          }
          priv.settings.data[r].push('');
        }
      }
      else {
        for (; r < rlen; r++) {
          priv.settings.data[r].splice(coords.col, 0, '');
        }
      }
      self.forceFullRender = true; //used when data was changed
    },

    /**
     * Removes row at the bottom of the data array
     * @param {Object} [coords] Optional. Coords of the cell which row will be removed
     * @param {Object} [toCoords] Required if coords is defined. Coords of the cell until which all rows will be removed
     */
    removeRow: function (coords, toCoords) {
      if (!coords || coords.row === self.countRows() - 1) {
        priv.settings.data.pop();
      }
      else {
        priv.settings.data.splice(coords.row, toCoords.row - coords.row + 1);
      }
      self.forceFullRender = true; //used when data was changed
    },

    /**
     * Removes col at the right of the data array
     * @param {Object} [coords] Optional. Coords of the cell which col will be removed
     * @param {Object} [toCoords] Required if coords is defined. Coords of the cell until which all cols will be removed
     */
    removeCol: function (coords, toCoords) {
      if (priv.dataType === 'object' || priv.settings.columns) {
        throw new Error("cannot remove column with object data source or columns option specified");
      }
      var r = 0;
      if (!coords || coords.col === self.countCols() - 1) {
        for (; r < self.countRows(); r++) {
          priv.settings.data[r].pop();
        }
      }
      else {
        var howMany = toCoords.col - coords.col + 1;
        for (; r < self.countRows(); r++) {
          priv.settings.data[r].splice(coords.col, howMany);
        }
      }
      self.forceFullRender = true; //used when data was changed
    },

    /**
     * Returns single value from the data array
     * @param {Number} row
     * @param {Number} prop
     */
    getVars: {},
    get: function (row, prop) {
      datamap.getVars.row = row;
      datamap.getVars.prop = prop;
      Handsontable.PluginHooks.run(self, 'beforeGet', datamap.getVars);
      if (typeof datamap.getVars.prop === 'string' && datamap.getVars.prop.indexOf('.') > -1) {
        var sliced = datamap.getVars.prop.split(".");
        var out = priv.settings.data[datamap.getVars.row];
        if (!out) {
          return null;
        }
        for (var i = 0, ilen = sliced.length; i < ilen; i++) {
          out = out[sliced[i]];
          if (typeof out === 'undefined') {
            return null;
          }
        }
        return out;
      }
      else {
        return priv.settings.data[datamap.getVars.row] ? priv.settings.data[datamap.getVars.row][datamap.getVars.prop] : null;
      }
    },

    /**
     * Saves single value to the data array
     * @param {Number} row
     * @param {Number} prop
     * @param {String} value
     */
    setVars: {},
    set: function (row, prop, value) {
      datamap.setVars.row = row;
      datamap.setVars.prop = prop;
      datamap.setVars.value = value;
      Handsontable.PluginHooks.run(self, 'beforeSet', datamap.setVars);
      if (typeof datamap.setVars.prop === 'string' && datamap.setVars.prop.indexOf('.') > -1) {
        var sliced = datamap.setVars.prop.split(".");
        var out = priv.settings.data[datamap.setVars.row];
        for (var i = 0, ilen = sliced.length - 1; i < ilen; i++) {
          out = out[sliced[i]];
        }
        out[sliced[i]] = datamap.setVars.value;
      }
      else {
        priv.settings.data[datamap.setVars.row][datamap.setVars.prop] = datamap.setVars.value;
      }
    },

    /**
     * Clears the data array
     */
    clear: function () {
      for (var r = 0; r < self.countRows(); r++) {
        for (var c = 0; c < self.countCols(); c++) {
          datamap.set(r, datamap.colToProp(c), '');
        }
      }
    },

    /**
     * Returns the data array
     * @return {Array}
     */
    getAll: function () {
      return priv.settings.data;
    },

    /**
     * Returns data range as array
     * @param {Object} start Start selection position
     * @param {Object} end End selection position
     * @return {Array}
     */
    getRange: function (start, end) {
      var r, rlen, c, clen, output = [], row;
      rlen = Math.max(start.row, end.row);
      clen = Math.max(start.col, end.col);
      for (r = Math.min(start.row, end.row); r <= rlen; r++) {
        row = [];
        for (c = Math.min(start.col, end.col); c <= clen; c++) {
          row.push(datamap.get(r, datamap.colToProp(c)));
        }
        output.push(row);
      }
      return output;
    },

    /**
     * Return data as text (tab separated columns)
     * @param {Object} start (Optional) Start selection position
     * @param {Object} end (Optional) End selection position
     * @return {String}
     */
    getText: function (start, end) {
      return SheetClip.stringify(datamap.getRange(start, end));
    }
  };

  grid = {
    /**
     * Alter grid
     * @param {String} action Possible values: "insert_row", "insert_col", "remove_row", "remove_col"
     * @param {Object} coords
     * @param {Object} [toCoords] Required only for actions "remove_row" and "remove_col"
     */
    alter: function (action, coords, toCoords) {
      var oldData, newData, changes, r, rlen, c, clen;
      oldData = $.extend(true, [], datamap.getAll());

      switch (action) {
        case "insert_row":
          if (self.countRows() < priv.settings.maxRows) {
            datamap.createRow(coords);
            if (priv.selStart.exists() && priv.selStart.row() >= coords.row) {
              priv.selStart.row(priv.selStart.row() + 1);
              selection.transformEnd(1, 0); //will call render() internally
            }
            else {
              selection.refreshBorders(); //it will call render and prepare methods
            }
          }
          break;

        case "insert_col":
          if (self.countCols() < priv.settings.maxCols) {
            datamap.createCol(coords);
            if (priv.selStart.exists() && priv.selStart.col() >= coords.col) {
              priv.selStart.col(priv.selStart.col() + 1);
              selection.transformEnd(0, 1); //will call render() internally
            }
            else {
              selection.refreshBorders(); //it will call render and prepare methods
            }
          }
          break;

        case "remove_row":
          datamap.removeRow(coords, toCoords);
          grid.keepEmptyRows();
          selection.refreshBorders(); //it will call render and prepare methods
          break;

        case "remove_col":
          datamap.removeCol(coords, toCoords);
          grid.keepEmptyRows();
          selection.refreshBorders(); //it will call render and prepare methods
          break;
      }

      changes = [];
      newData = datamap.getAll();
      for (r = 0, rlen = newData.length; r < rlen; r++) {
        for (c = 0, clen = newData[r].length; c < clen; c++) {
          changes.push([r, c, oldData[r] ? oldData[r][c] : null, newData[r][c]]);
        }
      }
      fireEvent("datachange.handsontable", [changes, 'alter']);
      grid.keepEmptyRows(); //makes sure that we did not add rows that will be removed in next refresh
    },

    /**
     * Makes sure there are empty rows at the bottom of the table
     */
    keepEmptyRows: function () {
      var r, c, rlen, clen, emptyRows = 0, emptyCols = 0, val;

      //count currently empty rows
      rows : for (r = self.countRows() - 1; r >= 0; r--) {
        for (c = 0, clen = self.countCols(); c < clen; c++) {
          val = datamap.get(r, datamap.colToProp(c));
          if (val !== '' && val !== null && typeof val !== 'undefined') {
            break rows;
          }
        }
        emptyRows++;
      }

      //should I add empty rows to data source to meet startRows?
      rlen = self.countRows();
      if (rlen < priv.settings.minRows) {
        for (r = 0; r < priv.settings.minRows - rlen; r++) {
          datamap.createRow();
        }
      }

      //should I add empty rows to meet minSpareRows?
      if (emptyRows < priv.settings.minSpareRows) {
        for (; emptyRows < priv.settings.minSpareRows && self.countRows() < priv.settings.maxRows; emptyRows++) {
          datamap.createRow();
        }
      }

      //count currently empty cols
      if (self.countRows() - 1 > 0) {
        cols : for (c = self.countCols() - 1; c >= 0; c--) {
          for (r = 0; r < self.countRows(); r++) {
            val = datamap.get(r, datamap.colToProp(c));
            if (val !== '' && val !== null && typeof val !== 'undefined') {
              break cols;
            }
          }
          emptyCols++;
        }
      }

      //should I add empty cols to meet minCols?
      if (!priv.settings.columns && self.countCols() < priv.settings.minCols) {
        for (; self.countCols() < priv.settings.minCols; emptyCols++) {
          datamap.createCol();
        }
      }

      //should I add empty cols to meet minSpareCols?
      if (!priv.settings.columns && priv.dataType === 'array' && emptyCols < priv.settings.minSpareCols) {
        for (; emptyCols < priv.settings.minSpareCols && self.countCols() < priv.settings.maxCols; emptyCols++) {
          datamap.createCol();
        }
      }

      if (priv.settings.enterBeginsEditing) {
        for (; (((priv.settings.minRows || priv.settings.minSpareRows) && self.countRows() > priv.settings.minRows) && (priv.settings.minSpareRows && emptyRows > priv.settings.minSpareRows)); emptyRows--) {
          datamap.removeRow();
        }
      }

      if (priv.settings.enterBeginsEditing && !priv.settings.columns) {
        for (; (((priv.settings.minCols || priv.settings.minSpareCols) && self.countCols() > priv.settings.minCols) && (priv.settings.minSpareCols && emptyCols > priv.settings.minSpareCols)); emptyCols--) {
          datamap.removeCol();
        }
      }

      var rowCount = self.countRows();
      var colCount = self.countCols();

      if (rowCount === 0 || colCount === 0) {
        selection.deselect();
      }

      if (priv.selStart.exists()) {
        var selectionChanged;
        var fromRow = priv.selStart.row();
        var fromCol = priv.selStart.col();
        var toRow = priv.selEnd.row();
        var toCol = priv.selEnd.col();

        //if selection is outside, move selection to last row
        if (fromRow > rowCount - 1) {
          fromRow = rowCount - 1;
          selectionChanged = true;
          if (toRow > fromRow) {
            toRow = fromRow;
          }
        } else if (toRow > rowCount - 1) {
          toRow = rowCount - 1;
          selectionChanged = true;
          if (fromRow > toRow) {
            fromRow = toRow;
          }
        }

        //if selection is outside, move selection to last row
        if (fromCol > colCount - 1) {
          fromCol = colCount - 1;
          selectionChanged = true;
          if (toCol > fromCol) {
            toCol = fromCol;
          }
        } else if (toCol > colCount - 1) {
          toCol = colCount - 1;
          selectionChanged = true;
          if (fromCol > toCol) {
            fromCol = toCol;
          }
        }

        if (selectionChanged) {
          self.selectCell(fromRow, fromCol, toRow, toCol);
        }
      }
    },

    /**
     * Populate cells at position with 2d array
     * @param {Object} start Start selection position
     * @param {Array} input 2d array
     * @param {Object} [end] End selection position (only for drag-down mode)
     * @param {String} [source="populateFromArray"]
     * @return {Object|undefined} ending td in pasted area (only if any cell was changed)
     */
    populateFromArray: function (start, input, end, source) {
      var r, rlen, c, clen, setData = [], current = {};
      rlen = input.length;
      if (rlen === 0) {
        return false;
      }
      current.row = start.row;
      current.col = start.col;
      for (r = 0; r < rlen; r++) {
        if ((end && current.row > end.row) || (!priv.settings.minSpareRows && current.row > self.countRows() - 1) || (current.row >= priv.settings.maxRows)) {
          break;
        }
        current.col = start.col;
        clen = input[r] ? input[r].length : 0;
        for (c = 0; c < clen; c++) {
          if ((end && current.col > end.col) || (!priv.settings.minSpareCols && current.col > self.countCols() - 1) || (current.col >= priv.settings.maxCols)) {
            break;
          }
          if (self.getCellMeta(current.row, current.col).isWritable) {
            var p = datamap.colToProp(current.col);
            setData.push([current.row, p, input[r][c]]);
          }
          current.col++;
          if (end && c === clen - 1) {
            c = -1;
          }
        }
        current.row++;
        if (end && r === rlen - 1) {
          r = -1;
        }
      }
      self.setDataAtCell(setData, null, null, source || 'populateFromArray');
    },

    /**
     * Returns the top left (TL) and bottom right (BR) selection coordinates
     * @param {Object[]} coordsArr
     * @returns {Object}
     */
    getCornerCoords: function (coordsArr) {
      function mapProp(func, array, prop) {
        function getProp(el) {
          return el[prop];
        }

        if (Array.prototype.map) {
          return func.apply(Math, array.map(getProp));
        }
        return func.apply(Math, $.map(array, getProp));
      }

      return {
        TL: {
          row: mapProp(Math.min, coordsArr, "row"),
          col: mapProp(Math.min, coordsArr, "col")
        },
        BR: {
          row: mapProp(Math.max, coordsArr, "row"),
          col: mapProp(Math.max, coordsArr, "col")
        }
      };
    },

    /**
     * Returns array of td objects given start and end coordinates
     */
    getCellsAtCoords: function (start, end) {
      var corners = grid.getCornerCoords([start, end]);
      var r, c, output = [];
      for (r = corners.TL.row; r <= corners.BR.row; r++) {
        for (c = corners.TL.col; c <= corners.BR.col; c++) {
          output.push(self.view.getCellAtCoords({
            row: r,
            col: c
          }));
        }
      }
      return output;
    }
  };

  this.selection = selection = { //this public assignment is only temporary
    /**
     * Starts selection range on given td object
     * @param {Object} coords
     */
    setRangeStart: function (coords) {
      selection.deselect();
      priv.selStart.coords(coords);
      selection.setRangeEnd(coords);
    },

    /**
     * Ends selection range on given td object
     * @param {Object} coords
     * @param {Boolean} [scrollToCell=true] If true, viewport will be scrolled to range end
     */
    setRangeEnd: function (coords, scrollToCell) {
      priv.selEnd.coords(coords);
      if (!priv.settings.multiSelect) {
        priv.selStart.coords(coords);
      }

      //set up current selection
      self.view.wt.selections.current.clear();
      self.view.wt.selections.current.add(priv.selStart.arr());

      //set up area selection
      self.view.wt.selections.area.clear();
      if (selection.isMultiple()) {
        self.view.wt.selections.area.add(priv.selStart.arr());
        self.view.wt.selections.area.add(priv.selEnd.arr());
      }

      //trigger handlers
      self.rootElement.triggerHandler("selection.handsontable", [priv.selStart.row(), priv.selStart.col(), priv.selEnd.row(), priv.selEnd.col()]);
      self.rootElement.triggerHandler("selectionbyprop.handsontable", [priv.selStart.row(), datamap.colToProp(priv.selStart.col()), priv.selEnd.row(), datamap.colToProp(priv.selEnd.col())]);
      if (scrollToCell !== false) {
        self.view.scrollViewport(coords);

        self.view.wt.draw(true); //these two lines are needed to fix scrolling viewport when cell dimensions are significantly bigger than assumed by Walkontable
        self.view.scrollViewport(coords);
      }
      selection.refreshBorders();
    },

    /**
     * Destroys editor, redraws borders around cells, prepares editor
     * @param {Boolean} revertOriginal
     * @param {Boolean} keepEditor
     */
    refreshBorders: function (revertOriginal, keepEditor) {
      if (!keepEditor) {
        editproxy.destroy(revertOriginal);
      }
      self.view.render();
      if (selection.isSelected() && !keepEditor) {
        editproxy.prepare();
      }
    },

    /**
     * Returns information if we have a multiselection
     * @return {Boolean}
     */
    isMultiple: function () {
      return !(priv.selEnd.col() === priv.selStart.col() && priv.selEnd.row() === priv.selStart.row());
    },

    /**
     * Selects cell relative to current cell (if possible)
     */
    transformStart: function (rowDelta, colDelta, force) {
      if (priv.selStart.row() + rowDelta > self.countRows() - 1) {
        if (force && priv.settings.minSpareRows > 0) {
          self.alter("insert_row", self.countRows());
        }
        else if (priv.settings.autoWrapCol && priv.selStart.col() + colDelta < self.countCols() - 1) {
          rowDelta = 1 - self.countRows();
          colDelta = 1;
        }
      }
      else if (priv.settings.autoWrapCol && priv.selStart.row() + rowDelta < 0 && priv.selStart.col() + colDelta >= 0) {
        rowDelta = self.countRows() - 1;
        colDelta = -1;
      }
      if (priv.selStart.col() + colDelta > self.countCols() - 1) {
        if (force && priv.settings.minSpareCols > 0) {
          self.alter("insert_col", self.countCols());
        }
        else if (priv.settings.autoWrapRow && priv.selStart.row() + rowDelta < self.countRows() - 1) {
          rowDelta = 1;
          colDelta = 1 - self.countCols();
        }
      }
      else if (priv.settings.autoWrapRow && priv.selStart.col() + colDelta < 0 && priv.selStart.row() + rowDelta >= 0) {
        rowDelta = -1;
        colDelta = self.countCols() - 1;
      }

      var totalRows = self.countRows();
      var totalCols = self.countCols();
      var coords = {
        row: (priv.selStart.row() + rowDelta),
        col: priv.selStart.col() + colDelta
      };

      if (coords.row < 0) {
        coords.row = 0;
      }
      else if (coords.row > 0 && coords.row >= totalRows) {
        coords.row = totalRows - 1;
      }

      if (coords.col < 0) {
        coords.col = 0;
      }
      else if (coords.col > 0 && coords.col >= totalCols) {
        coords.col = totalCols - 1;
      }

      selection.setRangeStart(coords);
    },

    /**
     * Sets selection end cell relative to current selection end cell (if possible)
     */
    transformEnd: function (rowDelta, colDelta) {
      if (priv.selEnd.exists()) {
        var totalRows = self.countRows();
        var totalCols = self.countCols();
        var coords = {
          row: priv.selEnd.row() + rowDelta,
          col: priv.selEnd.col() + colDelta
        };

        if (coords.row < 0) {
          coords.row = 0;
        }
        else if (coords.row > 0 && coords.row >= totalRows) {
          coords.row = totalRows - 1;
        }

        if (coords.col < 0) {
          coords.col = 0;
        }
        else if (coords.col > 0 && coords.col >= totalCols) {
          coords.col = totalCols - 1;
        }

        selection.setRangeEnd(coords);
      }
    },

    /**
     * Returns true if currently there is a selection on screen, false otherwise
     * @return {Boolean}
     */
    isSelected: function () {
      return priv.selEnd.exists();
    },

    /**
     * Returns true if coords is within current selection coords
     * @return {Boolean}
     */
    inInSelection: function (coords) {
      if (!selection.isSelected()) {
        return false;
      }
      var sel = grid.getCornerCoords([priv.selStart.coords(), priv.selEnd.coords()]);
      return (sel.TL.row <= coords.row && sel.BR.row >= coords.row && sel.TL.col <= coords.col && sel.BR.col >= coords.col);
    },

    /**
     * Deselects all selected cells
     */
    deselect: function () {
      if (!selection.isSelected()) {
        return;
      }
      priv.selEnd = new Handsontable.SelectionPoint(); //create new empty point to remove the existing one
      self.view.wt.selections.current.clear();
      self.view.wt.selections.area.clear();
      editproxy.destroy();
      selection.refreshBorders();
      self.rootElement.triggerHandler('deselect.handsontable');
    },

    /**
     * Select all cells
     */
    selectAll: function () {
      if (!priv.settings.multiSelect) {
        return;
      }
      selection.setRangeStart({
        row: 0,
        col: 0
      });
      selection.setRangeEnd({
        row: self.countRows() - 1,
        col: self.countCols() - 1
      }, false);
    },

    /**
     * Deletes data from selected cells
     */
    empty: function () {
      if (!selection.isSelected()) {
        return;
      }
      var corners = grid.getCornerCoords([priv.selStart.coords(), priv.selEnd.coords()]);
      var r, c, changes = [];
      for (r = corners.TL.row; r <= corners.BR.row; r++) {
        for (c = corners.TL.col; c <= corners.BR.col; c++) {
          if (self.getCellMeta(r, c).isWritable) {
            changes.push([r, datamap.colToProp(c), '']);
          }
        }
      }
      self.setDataAtCell(changes);
    }
  };

  this.autofill = autofill = { //this public assignment is only temporary
    handle: null,

    /**
     * Create fill handle and fill border objects
     */
    init: function () {
      if (!autofill.handle) {
        autofill.handle = {};
      }
      else {
        autofill.handle.disabled = false;
      }
    },

    /**
     * Hide fill handle and fill border permanently
     */
    disable: function () {
      autofill.handle.disabled = true;
    },

    /**
     * Selects cells down to the last row in the left column, then fills down to that cell
     */
    selectAdjacent: function () {
      var select, data, r, maxR, c;

      if (selection.isMultiple()) {
        select = self.view.wt.selections.area.getCorners();
      }
      else {
        select = self.view.wt.selections.current.getCorners();
      }

      data = datamap.getAll();
      rows : for (r = select[2] + 1; r < self.countRows(); r++) {
        for (c = select[1]; c <= select[3]; c++) {
          if (data[r][c]) {
            break rows;
          }
        }
        if (!!data[r][select[1] - 1] || !!data[r][select[3] + 1]) {
          maxR = r;
        }
      }
      if (maxR) {
        self.view.wt.selections.fill.clear();
        self.view.wt.selections.fill.add([select[0], select[1]]);
        self.view.wt.selections.fill.add([maxR, select[3]]);
        autofill.apply();
      }
    },

    /**
     * Apply fill values to the area in fill border, omitting the selection border
     */
    apply: function () {
      var drag, select, start, end;

      autofill.handle.isDragged = 0;

      drag = self.view.wt.selections.fill.getCorners();
      if (!drag) {
        return;
      }

      self.view.wt.selections.fill.clear();

      if (selection.isMultiple()) {
        select = self.view.wt.selections.area.getCorners();
      }
      else {
        select = self.view.wt.selections.current.getCorners();
      }

      if (drag[0] === select[0] && drag[1] < select[1]) {
        start = {
          row: drag[0],
          col: drag[1]
        };
        end = {
          row: drag[2],
          col: select[1] - 1
        };
      }
      else if (drag[0] === select[0] && drag[3] > select[3]) {
        start = {
          row: drag[0],
          col: select[3] + 1
        };
        end = {
          row: drag[2],
          col: drag[3]
        };
      }
      else if (drag[0] < select[0] && drag[1] === select[1]) {
        start = {
          row: drag[0],
          col: drag[1]
        };
        end = {
          row: select[0] - 1,
          col: drag[3]
        };
      }
      else if (drag[2] > select[2] && drag[1] === select[1]) {
        start = {
          row: select[2] + 1,
          col: drag[1]
        };
        end = {
          row: drag[2],
          col: drag[3]
        };
      }

      if (start) {
        grid.populateFromArray(start, SheetClip.parse(datamap.getText(priv.selStart.coords(), priv.selEnd.coords())), end, 'autofill');

        selection.setRangeStart({row: drag[0], col: drag[1]});
        selection.setRangeEnd({row: drag[2], col: drag[3]});
      }
      /*else {
       //reset to avoid some range bug
       selection.refreshBorders();
       }*/
    },

    /**
     * Show fill border
     */
    showBorder: function (coords) {
      coords.row = coords[0];
      coords.col = coords[1];

      var corners = grid.getCornerCoords([priv.selStart.coords(), priv.selEnd.coords()]);
      if (priv.settings.fillHandle !== 'horizontal' && (corners.BR.row < coords.row || corners.TL.row > coords.row)) {
        coords = [coords.row, corners.BR.col];
      }
      else if (priv.settings.fillHandle !== 'vertical') {
        coords = [corners.BR.row, coords.col];
      }
      else {
        return; //wrong direction
      }

      self.view.wt.selections.fill.clear();
      self.view.wt.selections.fill.add([priv.selStart.coords().row, priv.selStart.coords().col]);
      self.view.wt.selections.fill.add([priv.selEnd.coords().row, priv.selEnd.coords().col]);
      self.view.wt.selections.fill.add(coords);
      self.view.render();
    }
  };

  editproxy = { //this public assignment is only temporary
    /**
     * Create input field
     */
    init: function () {
      priv.editProxy = $('<textarea class="handsontableInput">');
      priv.editProxyHolder = $('<div class="handsontableInputHolder">');
      priv.editProxyHolder.append(priv.editProxy);

      function onClick(event) {
        event.stopPropagation();
      }

      function onCut() {
        setTimeout(function () {
          selection.empty();
        }, 100);
      }

      function onPaste() {
        setTimeout(function () {
          self.rootElement.one("datachange.handsontable", function (event, changes, source) {
            if (changes.length) {
              var last = changes[changes.length - 1];
              selection.setRangeEnd({row: last[0], col: self.propToCol(last[1])});
            }
          });

          var input = priv.editProxy[0].value.replace(/^[\r\n]*/g, '').replace(/[\r\n]*$/g, ''), //remove newline from the start and the end of the input
            inputArray = SheetClip.parse(input),
            coords = grid.getCornerCoords([priv.selStart.coords(), priv.selEnd.coords()]);

          grid.populateFromArray(coords.TL, inputArray, {
            row: Math.max(coords.BR.row, inputArray.length - 1 + coords.TL.row),
            col: Math.max(coords.BR.col, inputArray[0].length - 1 + coords.TL.col)
          }, 'paste');
        }, 100);
      }

      var $body = $(document.body);

      function onKeyDown(event) {
        if ($body.children('.context-menu-list:visible').length) {
          return;
        }

        if (event.keyCode === 17 || event.keyCode === 224 || event.keyCode === 91 || event.keyCode === 93) {
          //when CTRL is pressed, prepare selectable text in textarea
          //http://stackoverflow.com/questions/3902635/how-does-one-capture-a-macs-command-key-via-javascript
          editproxy.setCopyableText();
          return;
        }

        priv.lastKeyCode = event.keyCode;
        if (selection.isSelected()) {
          var ctrlDown = (event.ctrlKey || event.metaKey) && !event.altKey; //catch CTRL but not right ALT (which in some systems triggers ALT+CTRL)
          if (Handsontable.helper.isPrintableChar(event.keyCode) && ctrlDown) {
            if (event.keyCode === 65) { //CTRL + A
              selection.selectAll(); //select all cells
              editproxy.setCopyableText();
            }
            else if (event.keyCode === 88 && $.browser.opera) { //CTRL + X
              priv.editProxyHolder.triggerHandler('cut'); //simulate oncut for Opera
            }
            else if (event.keyCode === 86 && $.browser.opera) { //CTRL + V
              priv.editProxyHolder.triggerHandler('paste'); //simulate onpaste for Opera
            }
            else if (event.keyCode === 89 || (event.shiftKey && event.keyCode === 90)) { //CTRL + Y or CTRL + SHIFT + Z
              priv.undoRedo && priv.undoRedo.redo();
            }
            else if (event.keyCode === 90) { //CTRL + Z
              priv.undoRedo && priv.undoRedo.undo();
            }
            return;
          }

          var rangeModifier = event.shiftKey ? selection.setRangeEnd : selection.setRangeStart;

          switch (event.keyCode) {
            case 38: /* arrow up */
              if (event.shiftKey) {
                selection.transformEnd(-1, 0);
              }
              else {
                selection.transformStart(-1, 0);
              }
              event.preventDefault();
              break;

            case 9: /* tab */
              var tabMoves = typeof priv.settings.tabMoves === 'function' ? priv.settings.tabMoves(event) : priv.settings.tabMoves;
              if (event.shiftKey) {
                selection.transformStart(-tabMoves.row, -tabMoves.col); //move selection left
              }
              else {
                selection.transformStart(tabMoves.row, tabMoves.col, true); //move selection right (add a new column if needed)
              }
              event.preventDefault();
              break;

            case 39: /* arrow right */
              if (event.shiftKey) {
                selection.transformEnd(0, 1);
              }
              else {
                selection.transformStart(0, 1);
              }
              event.preventDefault();
              break;

            case 37: /* arrow left */
              if (event.shiftKey) {
                selection.transformEnd(0, -1);
              }
              else {
                selection.transformStart(0, -1);
              }
              event.preventDefault();
              break;

            case 8: /* backspace */
            case 46: /* delete */
              selection.empty(event);
              event.preventDefault();
              break;

            case 40: /* arrow down */
              if (event.shiftKey) {
                selection.transformEnd(1, 0); //expanding selection down with shift
              }
              else {
                selection.transformStart(1, 0); //move selection down
              }
              event.preventDefault();
              break;

            case 113: /* F2 */
              event.preventDefault(); //prevent Opera from opening Go to Page dialog
              break;

            case 13: /* return/enter */
              var enterMoves = typeof priv.settings.enterMoves === 'function' ? priv.settings.enterMoves(event) : priv.settings.enterMoves;
              if (event.shiftKey) {
                selection.transformStart(-enterMoves.row, -enterMoves.col); //move selection up
              }
              else {
                selection.transformStart(enterMoves.row, enterMoves.col, true); //move selection down (add a new row if needed)
              }
              event.preventDefault(); //don't add newline to field
              break;

            case 36: /* home */
              if (event.ctrlKey || event.metaKey) {
                rangeModifier({row: 0, col: priv.selStart.col()});
              }
              else {
                rangeModifier({row: priv.selStart.row(), col: 0});
              }
              break;

            case 35: /* end */
              if (event.ctrlKey || event.metaKey) {
                rangeModifier({row: self.countRows() - 1, col: priv.selStart.col()});
              }
              else {
                rangeModifier({row: priv.selStart.row(), col: self.countCols() - 1});
              }
              break;

            case 33: /* pg up */
              selection.transformStart(-self.countVisibleRows(), 0);
              self.view.wt.scrollVertical(-self.countVisibleRows());
              self.view.render();
              event.preventDefault(); //don't page up the window
              break;

            case 34: /* pg down */
              selection.transformStart(self.countVisibleRows(), 0);
              self.view.wt.scrollVertical(self.countVisibleRows());
              self.view.render();
              event.preventDefault(); //don't page down the window
              break;

            default:
              break;
          }
        }
      }

      priv.editProxy.on('click', onClick);
      priv.editProxyHolder.on('cut', onCut);
      priv.editProxyHolder.on('paste', onPaste);
      priv.editProxyHolder.on('keydown', onKeyDown);
      self.rootElement.append(priv.editProxyHolder);
    },

    /**
     * Destroy current editor, if exists
     * @param {Boolean} revertOriginal
     */
    destroy: function (revertOriginal) {
      if (typeof priv.editorDestroyer === "function") {
        priv.editorDestroyer(revertOriginal);
        priv.editorDestroyer = null;
      }
    },

    /**
     * Prepares copyable text in the invisible textarea
     */
    setCopyableText: function () {
      var startRow = Math.min(priv.selStart.row(), priv.selEnd.row());
      var startCol = Math.min(priv.selStart.col(), priv.selEnd.col());
      var endRow = Math.max(priv.selStart.row(), priv.selEnd.row());
      var endCol = Math.max(priv.selStart.col(), priv.selEnd.col());
      var finalEndRow = Math.min(endRow, startRow + priv.settings.copyRowsLimit - 1);
      var finalEndCol = Math.min(endCol, startCol + priv.settings.copyColsLimit - 1);

      priv.editProxy[0].value = datamap.getText({row: startRow, col: startCol}, {row: finalEndRow, col: finalEndCol});
      setTimeout(editproxy.focus, 1);

      if ((endRow !== finalEndRow || endCol !== finalEndCol) && priv.settings.onCopyLimit) {
        priv.settings.onCopyLimit(endRow - startRow + 1, endCol - startCol + 1, priv.settings.copyRowsLimit, priv.settings.copyColsLimit);
      }
    },

    /**
     * Prepare text input to be displayed at given grid cell
     */
    prepare: function () {
      priv.editProxy.height(priv.editProxy.parent().innerHeight() - 4);
      //editproxy.setCopyableText();
      priv.editProxy[0].value = '';
      setTimeout(editproxy.focus, 1);
      if (priv.settings.asyncRendering) {
        clearTimeout(window.prepareFrame);
        window.prepareFrame = setTimeout(function () {
          priv.editorDestroyer = self.view.applyCellTypeMethod('editor', self.view.getCellAtCoords(priv.selStart.coords()), priv.selStart.coords(), priv.editProxy);
        }, 0);
      }
      else {
        priv.editorDestroyer = self.view.applyCellTypeMethod('editor', self.view.getCellAtCoords(priv.selStart.coords()), priv.selStart.coords(), priv.editProxy);
      }
    },

    /**
     * Sets focus to textarea
     */
    focus: function () {
      try { //calling select() on hidden textarea causes problem in IE9 - similar to https://github.com/ajaxorg/ace/issues/251
        if(selection.isSelected()) {
          priv.editProxy[0].select();
        }
      }
      catch (e) {

      }
    }
  };

  this.init = function () {
    Handsontable.PluginHooks.run(self, 'beforeInit');
    editproxy.init();

    bindEvents();
    this.updateSettings(settings);
    this.view = new Handsontable.TableView(this);

    if (typeof priv.firstRun === 'object') {
      fireEvent('datachange.handsontable', priv.firstRun);
      priv.firstRun = false;
    }
    Handsontable.PluginHooks.run(self, 'afterInit');
  };

  validate = function (changes, source) {
    var validated = $.Deferred();
    var deferreds = [];

    if (source === 'paste') {
      //validate strict autocompletes
      var process = function (i) {
        var deferred = $.Deferred();
        deferreds.push(deferred);

        var originalVal = changes[i][3];
        var lowercaseVal = typeof originalVal === 'string' ? originalVal.toLowerCase() : null;

        return function (source) {
          var found = false;
          for (var s = 0, slen = source.length; s < slen; s++) {
            if (originalVal === source[s]) {
              found = true; //perfect match
              break;
            }
            else if (lowercaseVal === source[s].toLowerCase()) {
              changes[i][3] = source[s]; //good match, fix the case
              found = true;
              break;
            }
          }
          if (!found) {
            changes[i] = null;
          }
          deferred.resolve();
        }
      };

      for (var i = changes.length - 1; i >= 0; i--) {
        var cellProperties = self.getCellMeta(changes[i][0], changes[i][1]);
        if (cellProperties.strict && cellProperties.source) {
          var items = $.isFunction(cellProperties.source) ? cellProperties.source(changes[i][3], process(i)) : cellProperties.source;
          if (items) {
            process(i)(items)
          }
        }
      }
    }

    $.when(deferreds).then(function () {
      for (var i = changes.length - 1; i >= 0; i--) {
        if (changes[i] === null) {
          changes.splice(i, 1);
        }
      }

      if (priv.settings.onBeforeChange && changes.length) {
        var result = priv.settings.onBeforeChange.apply(self.rootElement[0], [changes, source]);
        if (typeof result === 'function') {
          $.when(result).then(function () {
            validated.resolve();
          });
        }
        else {
          if (result === false) {
            changes.splice(0, changes.length); //invalidate all changes (remove everything from array)
          }
          validated.resolve();
        }
      }
      else {
        validated.resolve();
      }
    });

    return $.when(validated);
  };

  var fireEvent = function (name, params) {
    if (priv.settings.asyncRendering) {
      setTimeout(function () {
        self.rootElement.triggerHandler(name, params);
      }, 0);
    }
    else {
      self.rootElement.triggerHandler(name, params);
    }
  };

  var bindEvents = function () {
    self.rootElement.on("datachange.handsontable", function (event, changes, source) {
      if (priv.settings.onChange) {
        priv.settings.onChange.apply(self.rootElement[0], [changes, source]);
      }
    });
    self.rootElement.on("selection.handsontable", function (event, row, col, endRow, endCol) {
      if (priv.settings.onSelection) {
        priv.settings.onSelection.apply(self.rootElement[0], [row, col, endRow, endCol]);
      }
    });
    self.rootElement.on("selectionbyprop.handsontable", function (event, row, prop, endRow, endProp) {
      if (priv.settings.onSelectionByProp) {
        priv.settings.onSelectionByProp.apply(self.rootElement[0], [row, prop, endRow, endProp]);
      }
    });
  };

  /**
   * Set data at given cell
   * @public
   * @param {Number|Array} row or array of changes in format [[row, col, value], ...]
   * @param {Number} prop
   * @param {String} value
   * @param {String} [source='edit'] String that identifies how this change will be described in changes array (useful in onChange callback)
   */
  this.setDataAtCell = function (row, prop, value, source) {
    var changes, i, ilen;

    if (typeof row === "object") { //is it an array of changes
      changes = row;
    }
    else if ($.isPlainObject(value)) { //backwards compatibility
      changes = value;
    }
    else {
      changes = [
        [row, prop, value]
      ];
    }

    for (i = 0, ilen = changes.length; i < ilen; i++) {
      changes[i].splice(2, 0, datamap.get(changes[i][0], changes[i][1])); //add old value at index 2
    }

    validate(changes, source).then(function () { //when validate is resolved...
      for (i = 0, ilen = changes.length; i < ilen; i++) {
        row = changes[i][0];
        prop = changes[i][1];
        var col = datamap.propToCol(prop);
        value = changes[i][3];

        if (priv.settings.minSpareRows) {
          while (row > self.countRows() - 1) {
            datamap.createRow();
          }
        }
        if (priv.dataType === 'array' && priv.settings.minSpareCols) {
          while (col > self.countCols() - 1) {
            datamap.createCol();
          }
        }
        datamap.set(row, prop, value);
      }
      self.forceFullRender = true; //used when data was changed
      grid.keepEmptyRows();
      selection.refreshBorders();
      fireEvent("datachange.handsontable", [changes, source || 'edit']);
    });
  };

  /**
   * Destroys current editor, renders and selects current cell. If revertOriginal != true, edited data is saved
   * @param {Boolean} revertOriginal
   */
  this.destroyEditor = function (revertOriginal) {
    selection.refreshBorders(revertOriginal);
  };

  /**
   * Populate cells at position with 2d array
   * @param {Object} start Start selection position
   * @param {Array} input 2d array
   * @param {Object} [end] End selection position (only for drag-down mode)
   * @param {String} [source="populateFromArray"]
   * @return {Object|undefined} ending td in pasted area (only if any cell was changed)
   */
  this.populateFromArray = function (start, input, end, source) {
    return grid.populateFromArray(start, input, end, source);
  };

  /**
   * Returns the top left (TL) and bottom right (BR) selection coordinates
   * @param {Object[]} coordsArr
   * @returns {Object}
   */
  this.getCornerCoords = function (coordsArr) {
    return grid.getCornerCoords(coordsArr);
  };

  /**
   * Returns current selection. Returns undefined if there is no selection.
   * @public
   * @return {Array} [topLeftRow, topLeftCol, bottomRightRow, bottomRightCol]
   */
  this.getSelected = function () { //https://github.com/warpech/jquery-handsontable/issues/44  //cjl
    if (selection.isSelected()) {
      var coords = grid.getCornerCoords([priv.selStart.coords(), priv.selEnd.coords()]);
      return [coords.TL.row, coords.TL.col, coords.BR.row, coords.BR.col];
    }
  };

  /**
   * Render visible data
   * @public
   */
  this.render = function () {
    if (self.view) {
      self.forceFullRender = true; //used when data was changed
      selection.refreshBorders(null, true);
      priv.editProxy.triggerHandler('refreshBorder'); //refresh size of the textarea in case cell dimensions have changed
    }
  };

  /**
   * Load data from array
   * @public
   * @param {Array} data
   */
  this.loadData = function (data, isInitial) {
    var rlen;
    priv.isPopulated = false;
    priv.settings.data = data;
    if ($.isPlainObject(priv.settings.dataSchema) || $.isPlainObject(data[0])) {
      priv.dataType = 'object';
    }
    else {
      priv.dataType = 'array';
    }
    if (data[0]) {
      priv.duckDataSchema = datamap.recursiveDuckSchema(data[0]);
    }
    else {
      priv.duckDataSchema = {};
    }
    datamap.createMap();

    if (isInitial) {
      rlen = self.countRows();
      if (priv.settings.startRows) {
        while (priv.settings.startRows > rlen) {
          datamap.createRow();
          rlen++;
        }
      }
    }

    grid.keepEmptyRows();
    Handsontable.PluginHooks.run(self, 'afterLoadData');

    if (priv.firstRun) {
      priv.firstRun = [null, 'loadData'];
    }
    else {
      fireEvent('datachange.handsontable', [null, 'loadData']);
      self.render();
    }
    priv.isPopulated = true;
    self.clearUndo();
  };

  /**
   * Return the current data object (the same that was passed by `data` configuration option or `loadData` method). Optionally you can provide cell range `r`, `c`, `r2`, `c2` to get only a fragment of grid data
   * @public
   * @param {Number} r (Optional) From row
   * @param {Number} c (Optional) From col
   * @param {Number} r2 (Optional) To row
   * @param {Number} c2 (Optional) To col
   * @return {Array|Object}
   */
  this.getData = function (r, c, r2, c2) {
    if (typeof r === 'undefined') {
      return datamap.getAll();
    }
    else {
      return datamap.getRange({row: r, col: c}, {row: r2, col: c2});
    }
  };

  /**
   * Update settings
   * @public
   */
  this.updateSettings = function (settings) {
    var i;

    if (typeof settings.rows !== "undefined") {
      throw new Error("'rows' setting is no longer supported. do you mean startRows, minRows or maxRows?");
    }
    if (typeof settings.cols !== "undefined") {
      throw new Error("'cols' setting is no longer supported. do you mean startCols, minCols or maxCols?");
    }

    if (typeof settings.undo !== "undefined") {
      if (priv.undoRedo && settings.undo === false) {
        priv.undoRedo = null;
      }
      else if (!priv.undoRedo && settings.undo === true) {
        priv.undoRedo = new Handsontable.UndoRedo(self);
      }
    }

    for (i in settings) {
      if (i === 'data') {
        continue; //loadData will be triggered later
      }
      else if (settings.hasOwnProperty(i)) {
        priv.settings[i] = settings[i];

        //launch extensions
        if (Handsontable.extension[i]) {
          priv.extensions[i] = new Handsontable.extension[i](self, settings[i]);
        }
      }
    }

    if (priv.settings.data === void 0) {
      if (settings.data === void 0) {
        settings.data = [];
        var row;
        for (var r = 0, rlen = priv.settings.startRows; r < rlen; r++) {
          row = [];
          for (var c = 0, clen = priv.settings.startCols; c < clen; c++) {
            row.push(null);
          }
          settings.data.push(row);
        }
      }
    }

    if (settings.data !== void 0) {
      self.loadData(settings.data, true);
    }
    else if (settings.columns !== void 0) {
      datamap.createMap();
    }

    if (typeof settings.fillHandle !== "undefined") {
      if (autofill.handle && settings.fillHandle === false) {
        autofill.disable();
      }
      else if (!autofill.handle && settings.fillHandle !== false) {
        autofill.init();
      }
    }

    grid.keepEmptyRows();
    if (self.view) {
      self.forceFullRender = true; //used when data was changed
      selection.refreshBorders(null, true);
    }
  };

  /**
   * Returns current settings object
   * @return {Object}
   */
  this.getSettings = function () {
    return priv.settings;
  };

  /**
   * Clears grid
   * @public
   */
  this.clear = function () {
    selection.selectAll();
    selection.empty();
  };

  /**
   * Return true if undo can be performed, false otherwise
   * @public
   */
  this.isUndoAvailable = function () {
    return priv.undoRedo && priv.undoRedo.isUndoAvailable();
  };

  /**
   * Return true if redo can be performed, false otherwise
   * @public
   */
  this.isRedoAvailable = function () {
    return priv.undoRedo && priv.undoRedo.isRedoAvailable();
  };

  /**
   * Undo last edit
   * @public
   */
  this.undo = function () {
    priv.undoRedo && priv.undoRedo.undo();
  };

  /**
   * Redo edit (used to reverse an undo)
   * @public
   */
  this.redo = function () {
    priv.undoRedo && priv.undoRedo.redo();
  };

  /**
   * Clears undo history
   * @public
   */
  this.clearUndo = function () {
    priv.undoRedo && priv.undoRedo.clear();
  };

  /**
   * Alters the grid
   * @param {String} action See grid.alter for possible values
   * @param {Number} from
   * @param {Number} [to] Optional. Used only for actions "remove_row" and "remove_col"
   * @public
   */
  this.alter = function (action, from, to) {
    if (typeof to === "undefined") {
      to = from;
    }
    switch (action) {
      case "insert_row":
      case "remove_row":
        grid.alter(action, {row: from, col: 0}, {row: to, col: 0});
        break;

      case "insert_col":
      case "remove_col":
        grid.alter(action, {row: 0, col: from}, {row: 0, col: to});
        break;

      default:
        throw Error('There is no such action "' + action + '"');
        break;
    }
  };

  /**
   * Returns <td> element corresponding to params row, col
   * @param {Number} row
   * @param {Number} col
   * @public
   * @return {Element}
   */
  this.getCell = function (row, col) {
    return self.view.getCellAtCoords({row: row, col: col});
  };

  /**
   * Returns property name associated with column number
   * @param {Number} col
   * @public
   * @return {String}
   */
  this.colToProp = function (col) {
    return datamap.colToProp(col);
  };

  /**
   * Returns column number associated with property name
   * @param {String} prop
   * @public
   * @return {Number}
   */
  this.propToCol = function (prop) {
    return datamap.propToCol(prop);
  };

  /**
   * Return cell value at `row`, `col`
   * @param {Number} row
   * @param {Number} col
   * @public
   * @return {string}
   */
  this.getDataAtCell = function (row, col) {
    return datamap.get(row, datamap.colToProp(col));
  };

  /**
   * Returns cell meta data object corresponding to params row, col
   * @param {Number} row
   * @param {Number} col
   * @public
   * @return {Object}
   */
  this.getCellMeta = function (row, col) {
    var cellProperites = {}
      , prop = datamap.colToProp(col);
    if (priv.settings.columns) {
      cellProperites = $.extend(true, cellProperites, priv.settings.columns[col] || {});
    }
    if (priv.settings.cells) {
      cellProperites = $.extend(true, cellProperites, priv.settings.cells(row, col, prop) || {});
    }
    cellProperites.isWritable = !cellProperites.readOnly;
    Handsontable.PluginHooks.run(self, 'afterGetCellMeta', row, col, cellProperites);
    return cellProperites;
  };

  /**
   * Return array of row headers (if they are enabled). If param `row` given, return header at given row as string
   * @param {Number} row (Optional)
   * @return {Array|String}
   */
  this.getRowHeader = function (row) {
    if (Object.prototype.toString.call(priv.settings.rowHeaders) === '[object Array]' && priv.settings.rowHeaders[row] !== void 0) {
      return priv.settings.rowHeaders[row];
    }
    else if (typeof priv.settings.rowHeaders === 'function') {
      return priv.settings.rowHeaders(row);
    }
    else if (priv.settings.rowHeaders && typeof priv.settings.rowHeaders !== 'string' && typeof priv.settings.rowHeaders !== 'number') {
      return row + 1;
    }
    else {
      return priv.settings.rowHeaders;
    }
  };

  /**
   * Return column header at given col as HTML string
   * @param {Number} col
   * @param {HTMLElement} TH
   */
  this.getColHeader = function (col, TH) {
    col = Handsontable.PluginModifiers.run(self, 'col', col);
    var DIV = document.createElement('DIV');
    DIV.className = 'relative';
    if (priv.settings.columns && priv.settings.columns[col] && priv.settings.columns[col].title) {
      DIV.innerHTML = '<span class="colHeader">' + priv.settings.columns[col].title + '</span>';
    }
    else if (Object.prototype.toString.call(priv.settings.colHeaders) === '[object Array]' && priv.settings.colHeaders[col] !== void 0) {
      DIV.innerHTML = '<span class="colHeader">' + priv.settings.colHeaders[col] + '</span>';
    }
    else if (typeof priv.settings.colHeaders === 'function') {
      DIV.innerHTML = '<span class="colHeader">' + priv.settings.colHeaders(col) + '</span>';
    }
    else if (priv.settings.colHeaders && typeof priv.settings.colHeaders !== 'string' && typeof priv.settings.colHeaders !== 'number') {
      var dividend = col + 1;
      var columnLabel = '';
      var modulo;
      while (dividend > 0) {
        modulo = (dividend - 1) % 26;
        columnLabel = String.fromCharCode(65 + modulo) + columnLabel;
        dividend = parseInt((dividend - modulo) / 26);
      }
      DIV.innerHTML = '<span class="colHeader">' + columnLabel + '</span>';
    }
    else {
      DIV.innerHTML = '<span class="colHeader">' + priv.settings.colHeaders + '</span>';
    }

    while (TH.firstChild) {
      TH.removeChild(TH.firstChild); //empty TH node
    }
    TH.appendChild(DIV);
    Handsontable.PluginHooks.run(self, 'afterGetColHeader', col, TH);
  };

  /**
   * Return column width
   * @param {Number} col
   * @return {Number}
   */
  this.getColWidth = function (col) {
    col = Handsontable.PluginModifiers.run(self, 'col', col);
    var response = {};
    if (priv.settings.columns && priv.settings.columns[col] && priv.settings.columns[col].width) {
      response.width = priv.settings.columns[col].width;
    }
    else if (Object.prototype.toString.call(priv.settings.colWidths) === '[object Array]' && priv.settings.colWidths[col] !== void 0) {
      response.width = priv.settings.colWidths[col];
    }
    else {
      response.width = 50;
    }
    Handsontable.PluginHooks.run(self, 'afterGetColWidth', col, response);
    return response.width;
  };

  /**
   * Return total number of rows in grid
   * @return {Number}
   */
  this.countRows = function () {
    return priv.settings.data.length;
  };

  /**
   * Return total number of columns in grid
   * @return {Number}
   */
  this.countCols = function () {
    if (priv.dataType === 'object') {
      if (priv.settings.columns && priv.settings.columns.length) {
        return priv.settings.columns.length;
      }
      else {
        return priv.colToProp.length;
      }
    }
    else if (priv.dataType === 'array') {
      if (priv.settings.columns && priv.settings.columns.length) {
        return priv.settings.columns.length;
      }
      else {
        return Math.max((priv.settings.columns && priv.settings.columns.length) || 0, (priv.settings.data && priv.settings.data[0] && priv.settings.data[0].length) || 0);
      }
    }
  };

  /**
   * Return index of first visible row
   * @return {Number}
   */
  this.rowOffset = function () {
    return self.view.wt.getSetting('offsetRow');
  };

  /**
   * Return index of first visible column
   * @return {Number}
   */
  this.colOffset = function () {
    return self.view.wt.getSetting('offsetColumn');
  };

  /**
   * Return number of visible rows
   * @return {Number}
   */
  this.countVisibleRows = function () {
    return self.view.wt.getSetting('viewportRows');
  };

  /**
   * Return number of visible columns
   * @return {Number}
   */
  this.countVisibleCols = function () {
    return self.view.wt.getSetting('viewportColumns');
  };

  /**
   * Selects cell on grid. Optionally selects range to another cell
   * @param {Number} row
   * @param {Number} col
   * @param {Number} [endRow]
   * @param {Number} [endCol]
   * @param {Boolean} [scrollToCell=true] If true, viewport will be scrolled to the selection
   * @public
   */
  this.selectCell = function (row, col, endRow, endCol, scrollToCell) {
    if (typeof row !== 'number' || row < 0 || row >= self.countRows()) {
      return false;
    }
    if (typeof col !== 'number' || col < 0 || col >= self.countCols()) {
      return false;
    }
    if (typeof endRow !== "undefined") {
      if (typeof endRow !== 'number' || endRow < 0 || endRow >= self.countRows()) {
        return false;
      }
      if (typeof endCol !== 'number' || endCol < 0 || endCol >= self.countCols()) {
        return false;
      }
    }
    priv.selStart.coords({row: row, col: col});
    if (typeof endRow === "undefined") {
      selection.setRangeEnd({row: row, col: col}, scrollToCell);
    }
    else {
      selection.setRangeEnd({row: endRow, col: endCol}, scrollToCell);
    }
  };

  this.selectCellByProp = function (row, prop, endRow, endProp, scrollToCell) {
    arguments[1] = datamap.propToCol(arguments[1]);
    if (typeof arguments[3] !== "undefined") {
      arguments[3] = datamap.propToCol(arguments[3]);
    }
    return self.selectCell.apply(self, arguments);
  };

  /**
   * Deselects current sell selection on grid
   * @public
   */
  this.deselectCell = function () {
    selection.deselect();
  };

  /**
   * Remove grid from DOM
   * @public
   */
  this.destroy = function () {
    self.rootElement.empty();
    self.rootElement.removeData('handsontable');
    self.rootElement.off('.handsontable');
  };

  /**
   * Handsontable version
   */
  this.version = '0.8.3'; //inserted by grunt from package.json
};

var settings = {
  'data': void 0,
  'startRows': 5,
  'startCols': 5,
  'minRows': 0,
  'minCols': 0,
  'maxRows': Infinity,
  'maxCols': Infinity,
  'minSpareRows': 0,
  'minSpareCols': 0,
  'multiSelect': true,
  'fillHandle': true,
  'undo': true,
  'outsideClickDeselects': true,
  'enterBeginsEditing': true,
  'enterMoves': {row: 1, col: 0},
  'tabMoves': {row: 0, col: 1},
  'autoWrapRow': false,
  'autoWrapCol': false,
  'copyRowsLimit': 1000,
  'copyColsLimit': 1000,
  'currentRowClassName': void 0,
  'currentColClassName': void 0,
  'asyncRendering': true,
  'stretchH': 'hybrid'
};

$.fn.handsontable = function (action) {
  var i, ilen, args, output = [], userSettings;
  if (typeof action !== 'string') { //init
    userSettings = action || {};
    return this.each(function () {
      var $this = $(this);
      if ($this.data("handsontable")) {
        instance = $this.data("handsontable");
        instance.updateSettings(userSettings);
      }
      else {
        var currentSettings = $.extend(true, {}, settings), instance;
        for (i in userSettings) {
          if (userSettings.hasOwnProperty(i)) {
            currentSettings[i] = userSettings[i];
          }
        }
        instance = new Handsontable.Core($this, currentSettings);
        $this.data("handsontable", instance);
        instance.init();
      }
    });
  }
  else {
    args = [];
    if (arguments.length > 1) {
      for (i = 1, ilen = arguments.length; i < ilen; i++) {
        args.push(arguments[i]);
      }
    }
    this.each(function () {
      output = $(this).data("handsontable")[action].apply(this, args);
    });
    return output;
  }
};
/**
 * Handsontable TableView constructor
 * @param {Object} instance
 */
Handsontable.TableView = function (instance) {
  var that = this;

  this.instance = instance;
  var settings = this.instance.getSettings();

  instance.rootElement.addClass('handsontable');
  var $table = $('<table class="htCore"><thead></thead><tbody></tbody></table>');
  instance.rootElement.prepend($table);
  this.overflow = instance.rootElement.css('overflow');
  if ((settings.width || settings.height) && !(this.overflow === 'scroll' || this.overflow === 'auto')) {
    this.overflow = 'auto';
  }
  if (this.overflow === 'scroll' || this.overflow === 'auto') {
    //instance.rootElement[0].style.overflow = 'visible';
    instance.rootElement[0].style.overflow = 'hidden';
  }
  this.determineContainerSize();
  //instance.rootElement[0].style.height = '';
  //instance.rootElement[0].style.width = '';

  var isMouseDown
    , dragInterval;

  $(document.body).on('mouseup', function () {
    isMouseDown = false;
    clearInterval(dragInterval);
    dragInterval = null;

    if (instance.autofill.handle && instance.autofill.handle.isDragged) {
      if (instance.autofill.handle.isDragged > 1) {
        instance.autofill.apply();
      }
      instance.autofill.handle.isDragged = 0;
    }
  });

  $(document.documentElement).on('mousedown', function (event) {
    var next = event.target;
    if (next !== that.wt.wtTable.spreader) { //immediate click on "spreader" means click on the right side of vertical scrollbar
      while (next !== null && next !== document.documentElement) {
        if (next === instance.rootElement[0] || $(next).attr('id') === 'context-menu-layer' || $(next).is('.context-menu-list') || $(next).is('.typeahead li')) {
          return; //click inside container
        }
        next = next.parentNode;
      }
    }

    if (that.instance.getSettings().outsideClickDeselects) {
      that.instance.deselectCell();
    }
    else {
      that.instance.destroyEditor();
    }
  });

  $table.on('selectstart', function (event) {
    //https://github.com/warpech/jquery-handsontable/issues/160
    //selectstart is IE only event. Prevent text from being selected when performing drag down in IE8
    event.preventDefault();
  });

  $table.on('mouseenter', function () {
    if (dragInterval) { //if dragInterval was set (that means mouse was really outside of table, not over an element that is outside of <table> in DOM
      clearInterval(dragInterval);
      dragInterval = null;
    }
  });

  $table.on('mouseleave', function (event) {
    if (!(isMouseDown || (instance.autofill.handle && instance.autofill.handle.isDragged))) {
      return;
    }

    var tolerance = 1 //this is needed because width() and height() contains stuff like cell borders
      , offset = that.wt.wtDom.offset($table[0])
      , offsetTop = offset.top + tolerance
      , offsetLeft = offset.left + tolerance
      , width = that.containerWidth - that.wt.getSetting('scrollbarWidth') - 2 * tolerance
      , height = that.containerHeight - that.wt.getSetting('scrollbarHeight') - 2 * tolerance
      , method
      , row = 0
      , col = 0
      , dragFn;

    if (event.pageY < offsetTop) { //top edge crossed
      row = -1;
      method = 'scrollVertical';
    }
    else if (event.pageY >= offsetTop + height) { //bottom edge crossed
      row = 1;
      method = 'scrollVertical';
    }
    else if (event.pageX < offsetLeft) { //left edge crossed
      col = -1;
      method = 'scrollHorizontal';
    }
    else if (event.pageX >= offsetLeft + width) { //right edge crossed
      col = 1;
      method = 'scrollHorizontal';
    }

    if (method) {
      dragFn = function () {
        if (isMouseDown || (instance.autofill.handle && instance.autofill.handle.isDragged)) {
          //instance.selection.transformEnd(row, col);
          that.wt[method](row + col).draw();
        }
      };
      dragFn();
      dragInterval = setInterval(dragFn, 100);
    }
  });

  var walkontableConfig = {
    table: $table[0],
    async: settings.asyncRendering,
    stretchH: settings.stretchH,
    data: instance.getDataAtCell,
    totalRows: instance.countRows,
    totalColumns: instance.countCols,
    offsetRow: 0,
    offsetColumn: 0,
    displayRows: null,
    displayColumns: null,
    width: this.containerWidth,
    height: this.containerHeight,
    frozenColumns: settings.rowHeaders ? [instance.getRowHeader] : null,
    columnHeaders: settings.colHeaders ? instance.getColHeader : null,
    columnWidth: instance.getColWidth,
    cellRenderer: function (row, column, TD) {
      that.applyCellTypeMethod('renderer', TD, {row: row, col: column}, instance.getDataAtCell(row, column));
    },
    currentRowClassName: settings.currentRowClassName,
    currentColumnClassName: settings.currentColClassName,
    selections: {
      current: {
        className: 'current',
        border: {
          width: 2,
          color: '#5292F7',
          style: 'solid',
          cornerVisible: function () {
            return settings.fillHandle && !texteditor.isCellEdited && !instance.selection.isMultiple()
          }
        }
      },
      area: {
        className: 'area',
        border: {
          width: 1,
          color: '#89AFF9',
          style: 'solid',
          cornerVisible: function () {
            return settings.fillHandle && !texteditor.isCellEdited && instance.selection.isMultiple()
          }
        }
      },
      fill: {
        className: 'fill',
        border: {
          width: 1,
          color: 'red',
          style: 'solid'
        }
      }
    },
    onCellMouseDown: function (event, coords, TD) {
      isMouseDown = true;
      var coordsObj = {row: coords[0], col: coords[1]};
      if (event.button === 2 && instance.selection.inInSelection(coordsObj)) { //right mouse button
        //do nothing
      }
      else if (event.shiftKey) {
        instance.selection.setRangeEnd(coordsObj);
      }
      else {
        instance.selection.setRangeStart(coordsObj);
      }
    },
    onCellMouseOver: function (event, coords, TD) {
      var coordsObj = {row: coords[0], col: coords[1]};
      if (isMouseDown) {
        instance.selection.setRangeEnd(coordsObj);
      }
      else if (instance.autofill.handle && instance.autofill.handle.isDragged) {
        instance.autofill.handle.isDragged++;
        instance.autofill.showBorder(coords);
      }
    },
    onCellCornerMouseDown: function (event) {
      instance.autofill.handle.isDragged = 1;
      event.preventDefault();
    },
    onCellCornerDblClick: function (event) {
      instance.autofill.selectAdjacent();
    }
  };

  Handsontable.PluginHooks.run(this.instance, 'walkontableConfig', walkontableConfig);

  this.wt = new Walkontable(walkontableConfig);
  this.instance.forceFullRender = true; //used when data was changed
  this.render();

  $(window).on('resize', function () {
    that.determineContainerSize();
    that.wt.update('width', that.containerWidth);
    that.wt.update('height', that.containerHeight);
    that.instance.forceFullRender = true;
    that.render();
  });

  $(that.wt.wtTable.spreader).on('mousedown.handsontable, contextmenu.handsontable', function (event) {
    if(event.target === that.wt.wtTable.spreader && event.which === 3) { //right mouse button exactly on spreader means right clickon the right hand side of vertical scrollbar
      event.stopPropagation();
    }
  });
};

Handsontable.TableView.prototype.determineContainerSize = function () {
  this.instance.rootElement[0].firstChild.style.display = 'none';
  var settings = this.instance.getSettings();
  this.containerWidth = settings.width;
  this.containerHeight = settings.height;

  var computedWidth = this.instance.rootElement.width();
  var computedHeight = this.instance.rootElement.height();
  if (settings.width === void 0 && computedWidth > 0) {
    this.containerWidth = computedWidth;
  }

  if (this.overflow === 'scroll' || this.overflow === 'auto') {
    if (settings.height === void 0 && computedHeight > 0) {
      this.containerHeight = computedHeight;
    }
  }
  this.instance.rootElement[0].firstChild.style.display = 'table';
};

Handsontable.TableView.prototype.render = function () {
  if (this.instance.forceFullRender) {
    Handsontable.PluginHooks.run(this.instance, 'beforeRender');
  }
  this.wt.draw(!this.instance.forceFullRender);
  this.instance.rootElement.triggerHandler('render.handsontable');
  this.instance.forceFullRender = false;
  if (this.instance.forceFullRender) {
    Handsontable.PluginHooks.run(this.instance, 'afterRender');
  }
};

Handsontable.TableView.prototype.applyCellTypeMethod = function (methodName, td, coords, extraParam) {
  var prop = this.instance.colToProp(coords.col)
    , method
    , cellProperties = this.instance.getCellMeta(coords.row, coords.col);

  if (typeof cellProperties.type === 'string') {
    switch (cellProperties.type) {
      case 'autocomplete':
        cellProperties.type = Handsontable.AutocompleteCell;
        break;

      case 'checkbox':
        cellProperties.type = Handsontable.CheckboxCell;
        break;
    }
  }

  if (cellProperties.type && typeof cellProperties.type[methodName] === "function") {
    method = cellProperties.type[methodName];
  }
  if (typeof method !== "function") {
    method = Handsontable.TextCell[methodName];
  }
  return method(this.instance, td, coords.row, coords.col, prop, extraParam, cellProperties);
};

/**
 * Returns td object given coordinates
 */
Handsontable.TableView.prototype.getCellAtCoords = function (coords) {
  var td = this.wt.wtTable.getCell([coords.row, coords.col]);
  if (td < 0) { //there was an exit code (cell is out of bounds)
    return null;
  }
  else {
    return td;
  }
};

/**
 * Scroll viewport to selection
 * @param coords
 */
Handsontable.TableView.prototype.scrollViewport = function (coords) {
  this.wt.scrollViewport([coords.row, coords.col]);
};
/**
 * Returns true if keyCode represents a printable character
 * @param {Number} keyCode
 * @return {Boolean}
 */
Handsontable.helper.isPrintableChar = function (keyCode) {
  return ((keyCode == 32) || //space
    (keyCode >= 48 && keyCode <= 57) || //0-9
    (keyCode >= 96 && keyCode <= 111) || //numpad
    (keyCode >= 186 && keyCode <= 192) || //;=,-./`
    (keyCode >= 219 && keyCode <= 222) || //[]{}\|"'
    keyCode >= 226 || //special chars (229 for Asian chars)
    (keyCode >= 65 && keyCode <= 90)); //a-z
};

/**
 * Converts a value to string
 * @param value
 * @return {String}
 */
Handsontable.helper.stringify = function (value) {
  switch (typeof value) {
    case 'string':
    case 'number':
      return value + '';
      break;

    case 'object':
      if (value === null) {
        return '';
      }
      else {
        return value.toString();
      }
      break;

    case 'undefined':
      return '';
      break;

    default:
      return value.toString();
  }
};

/**
 * Handsontable UndoRedo class
 */
Handsontable.UndoRedo = function (instance) {
  var that = this;
  this.instance = instance;
  this.clear();
  instance.rootElement.on("datachange.handsontable", function (event, changes, origin) {
    if (origin !== 'undo' && origin !== 'redo') {
      that.add(changes);
    }
  });
};

/**
 * Undo operation from current revision
 */
Handsontable.UndoRedo.prototype.undo = function () {
  var i, ilen;
  if (this.isUndoAvailable()) {
    var setData = $.extend(true, [], this.data[this.rev]);
    for (i = 0, ilen = setData.length; i < ilen; i++) {
      setData[i].splice(3, 1);
    }
    this.instance.setDataAtCell(setData, null, null, 'undo');
    this.rev--;
  }
};

/**
 * Redo operation from current revision
 */
Handsontable.UndoRedo.prototype.redo = function () {
  var i, ilen;
  if (this.isRedoAvailable()) {
    this.rev++;
    var setData = $.extend(true, [], this.data[this.rev]);
    for (i = 0, ilen = setData.length; i < ilen; i++) {
      setData[i].splice(2, 1);
    }
    this.instance.setDataAtCell(setData, null, null, 'redo');
  }
};

/**
 * Returns true if undo point is available
 * @return {Boolean}
 */
Handsontable.UndoRedo.prototype.isUndoAvailable = function () {
  return (this.rev >= 0);
};

/**
 * Returns true if redo point is available
 * @return {Boolean}
 */
Handsontable.UndoRedo.prototype.isRedoAvailable = function () {
  return (this.rev < this.data.length - 1);
};

/**
 * Add new history poins
 * @param changes
 */
Handsontable.UndoRedo.prototype.add = function (changes) {
  this.rev++;
  this.data.splice(this.rev); //if we are in point abcdef(g)hijk in history, remove everything after (g)
  this.data.push(changes);
};

/**
 * Clears undo history
 */
Handsontable.UndoRedo.prototype.clear = function () {
  this.data = [];
  this.rev = -1;
};
Handsontable.SelectionPoint = function () {
  this._row = null; //private use intended
  this._col = null;
};

Handsontable.SelectionPoint.prototype.exists = function () {
  return (this._row !== null);
};

Handsontable.SelectionPoint.prototype.row = function (val) {
  if (val !== void 0) {
    this._row = val;
  }
  return this._row;
};

Handsontable.SelectionPoint.prototype.col = function (val) {
  if (val !== void 0) {
    this._col = val;
  }
  return this._col;
};

Handsontable.SelectionPoint.prototype.coords = function (coords) {
  if (coords !== void 0) {
    this._row = coords.row;
    this._col = coords.col;
  }
  return {
    row: this._row,
    col: this._col
  }
};

Handsontable.SelectionPoint.prototype.arr = function (arr) {
  if (arr !== void 0) {
    this._row = arr[0];
    this._col = arr[1];
  }
  return [this._row, this._col]
};
/**
 * Default text renderer
 * @param {Object} instance Handsontable instance
 * @param {Element} td Table cell where to render
 * @param {Number} row
 * @param {Number} col
 * @param {String|Number} prop Row object property name
 * @param value Value to render (remember to escape unsafe HTML before inserting to DOM!)
 * @param {Object} cellProperties Cell properites (shared by cell renderer and editor)
 */
Handsontable.TextRenderer = function (instance, td, row, col, prop, value, cellProperties) {
  var escaped = Handsontable.helper.stringify(value);
  escaped = escaped.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;"); //escape html special chars
  td.innerHTML = escaped.replace(/\n/g, '<br/>');
};
/**
 * Autocomplete renderer
 * @param {Object} instance Handsontable instance
 * @param {Element} td Table cell where to render
 * @param {Number} row
 * @param {Number} col
 * @param {String|Number} prop Row object property name
 * @param value Value to render (remember to escape unsafe HTML before inserting to DOM!)
 * @param {Object} cellProperties Cell properites (shared by cell renderer and editor)
 */
Handsontable.AutocompleteRenderer = function (instance, td, row, col, prop, value, cellProperties) {
  var $td = $(td);
  var $text = $('<div class="htAutocomplete"></div>');
  var $arrow = $('<div class="htAutocompleteArrow">&#x25BC;</div>');

  $arrow.mouseup(function (event) {
    instance.view.wt.getSetting('onCellDblClick');
  });

  Handsontable.TextCell.renderer(instance, $text[0], row, col, prop, value, cellProperties);

  if ($text.html() === '') {
    $text.html('&nbsp;');
  }

  $text.append($arrow);
  $td.empty().append($text);
};
/**
 * Checkbox renderer
 * @param {Object} instance Handsontable instance
 * @param {Element} td Table cell where to render
 * @param {Number} row
 * @param {Number} col
 * @param {String|Number} prop Row object property name
 * @param value Value to render (remember to escape unsafe HTML before inserting to DOM!)
 * @param {Object} cellProperties Cell properites (shared by cell renderer and editor)
 */
Handsontable.CheckboxRenderer = function (instance, td, row, col, prop, value, cellProperties) {
  if (typeof cellProperties.checkedTemplate === "undefined") {
    cellProperties.checkedTemplate = true;
  }
  if (typeof cellProperties.uncheckedTemplate === "undefined") {
    cellProperties.uncheckedTemplate = false;
  }
  if (value === cellProperties.checkedTemplate || value === Handsontable.helper.stringify(cellProperties.checkedTemplate)) {
    td.innerHTML = "<input type='checkbox' checked autocomplete='no'>";
  }
  else if (value === cellProperties.uncheckedTemplate || value === Handsontable.helper.stringify(cellProperties.uncheckedTemplate)) {
    td.innerHTML = "<input type='checkbox' autocomplete='no'>";
  }
  else if (value === null) { //default value
    td.innerHTML = "<input type='checkbox' autocomplete='no' style='opacity: 0.5'>";
  }
  else {
    td.innerHTML = "#bad value#";
  }

  var $input = $(td).find('input:first');
  $input.mousedown(function (event) {
    if (!$(this).is(':checked')) {
      instance.setDataAtCell(row, prop, cellProperties.checkedTemplate);
    }
    else {
      instance.setDataAtCell(row, prop, cellProperties.uncheckedTemplate);
    }
    event.stopPropagation(); //otherwise can confuse mousedown handler
  });

  $input.mouseup(function (event) {
    event.stopPropagation(); //otherwise can confuse dblclick handler
  });

  return td;
};
var texteditor = {
  isCellEdited: false,

  /**
   * Returns caret position in edit proxy
   * @author http://stackoverflow.com/questions/263743/how-to-get-caret-position-in-textarea
   * @return {Number}
   */
  getCaretPosition: function (keyboardProxy) {
    var el = keyboardProxy[0];
    if (el.selectionStart) {
      return el.selectionStart;
    }
    else if (document.selection) {
      el.focus();
      var r = document.selection.createRange();
      if (r == null) {
        return 0;
      }
      var re = el.createTextRange(),
        rc = re.duplicate();
      re.moveToBookmark(r.getBookmark());
      rc.setEndPoint('EndToStart', re);
      return rc.text.length;
    }
    return 0;
  },

  /**
   * Sets caret position in edit proxy
   * @author http://blog.vishalon.net/index.php/javascript-getting-and-setting-caret-position-in-textarea/
   * @param {Number}
   */
  setCaretPosition: function (keyboardProxy, pos) {
    var el = keyboardProxy[0];
    if (el.setSelectionRange) {
      el.focus();
      el.setSelectionRange(pos, pos);
    }
    else if (el.createTextRange) {
      var range = el.createTextRange();
      range.collapse(true);
      range.moveEnd('character', pos);
      range.moveStart('character', pos);
      range.select();
    }
  },

  /**
   * Shows text input in grid cell
   */
  beginEditing: function (instance, td, row, col, prop, keyboardProxy, useOriginalValue, suffix) {
    if (texteditor.isCellEdited) {
      return;
    }
    texteditor.isCellEdited = true;

    var coords = {row: row, col: col};
    instance.view.scrollViewport(coords);
    instance.view.render();

    keyboardProxy.on('cut.editor', function (event) {
      event.stopPropagation();
    });

    keyboardProxy.on('paste.editor', function (event) {
      event.stopPropagation();
    });

    if (!instance.getCellMeta(row, col).isWritable) {
      return;
    }

    if (useOriginalValue) {
      var original = instance.getDataAtCell(row, prop);
      original = Handsontable.helper.stringify(original) + (suffix || '');
      keyboardProxy.val(original);
      texteditor.setCaretPosition(keyboardProxy, original.length);
    }
    else {
      keyboardProxy.val('');
    }

    if (instance.getSettings().asyncRendering) {
      setTimeout(function () {
        texteditor.refreshDimensions(instance, row, col, keyboardProxy);
      }, 0);
    }
    else {
      texteditor.refreshDimensions(instance, row, col, keyboardProxy);
    }
  },

  refreshDimensions: function (instance, row, col, keyboardProxy) {
    if (!texteditor.isCellEdited) {
      return;
    }

    ///start prepare textarea position
    var $td = $(instance.getCell(row, col)); //because old td may have been scrolled out with scrollViewport
    var currentOffset = $td.offset();
    var containerOffset = instance.rootElement.offset();
    var scrollTop = instance.rootElement.scrollTop();
    var scrollLeft = instance.rootElement.scrollLeft();
    var editTop = currentOffset.top - containerOffset.top + scrollTop - 1;
    var editLeft = currentOffset.left - containerOffset.left + scrollLeft - 1;

    var settings = instance.getSettings();
    var rowHeadersCount = settings.rowHeaders === false ? 0 : 1;
    var colHeadersCount = settings.colHeaders === false ? 0 : 1;

    if (editTop < 0) {
      editTop = 0;
    }
    if (editLeft < 0) {
      editLeft = 0;
    }

    if (rowHeadersCount > 0 && parseInt($td.css('border-top-width')) > 0) {
      editTop += 1;
    }
    if (colHeadersCount > 0 && parseInt($td.css('border-left-width')) > 0) {
      editLeft += 1;
    }

    if ($.browser.msie && parseInt($.browser.version, 10) <= 7) {
      editTop -= 1;
    }

    keyboardProxy.parent().addClass('htHidden').css({
      top: editTop,
      left: editLeft
    });
    ///end prepare textarea position

    var width = $td.width()
      , height = $td.outerHeight() - 4;

    if (parseInt($td.css('border-top-width')) > 0) {
      height -= 1;
    }
    if (parseInt($td.css('border-left-width')) > 0) {
      if (rowHeadersCount > 0) {
        width -= 1;
      }
    }

    keyboardProxy.autoResize({
      maxHeight: 200,
      minHeight: height,
      minWidth: width,
      maxWidth: Math.max(168, width),
      animate: false,
      extraSpace: 0
    });

    keyboardProxy.parent().removeClass('htHidden');

    instance.rootElement.triggerHandler('beginediting.handsontable');

    setTimeout(function () {
      //async fix for Firefox 3.6.28 (needs manual testing)
      keyboardProxy.parent().css({
        overflow: 'visible'
      });
    }, 1);
  },

  /**
   * Finishes text input in selected cells
   */
  finishEditing: function (instance, td, row, col, prop, keyboardProxy, isCancelled, ctrlDown) {
    if (texteditor.triggerOnlyByDestroyer) {
      return;
    }
    if (texteditor.isCellEdited) {
      texteditor.isCellEdited = false;
      var val;
      if (isCancelled) {
        val = [
          [texteditor.originalValue]
        ];
      }
      else {
        val = [
          [$.trim(keyboardProxy.val())]
        ];
      }
      if (ctrlDown) { //if ctrl+enter and multiple cells selected, behave like Excel (finish editing and apply to all cells)
        var sel = instance.getSelected();
        instance.populateFromArray({row: sel[0], col: sel[1]}, val, {row: sel[2], col: sel[3]}, false, 'edit');
      }
      else {
        instance.populateFromArray({row: row, col: col}, val, null, false, 'edit');
      }
    }
    keyboardProxy.off(".editor");
    instance.view.wt.update('onCellDblClick', null);

    keyboardProxy.css({
      width: 0,
      height: 0
    });
    keyboardProxy.parent().addClass('htHidden').css({
      overflow: 'hidden'
    });

    instance.rootElement.triggerHandler('finishediting.handsontable');
  }
};

/**
 * Default text editor
 * @param {Object} instance Handsontable instance
 * @param {Element} td Table cell where to render
 * @param {Number} row
 * @param {Number} col
 * @param {String|Number} prop Row object property name
 * @param {Object} keyboardProxy jQuery element of keyboard proxy that contains current editing value
 * @param {Object} cellProperties Cell properites (shared by cell renderer and editor)
 */
Handsontable.TextEditor = function (instance, td, row, col, prop, keyboardProxy, cellProperties) {
  texteditor.isCellEdited = false;
  texteditor.originalValue = instance.getDataAtCell(row, prop);
  texteditor.triggerOnlyByDestroyer = cellProperties.strict;

  keyboardProxy.parent().addClass('htHidden').css({
    top: 0,
    left: 0,
    overflow: 'hidden'
  });
  keyboardProxy.css({
    width: 0,
    height: 0
  });

  /*keyboardProxy.on('blur.editor', function () {
    if (texteditor.isCellEdited) {
      texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, false);
    }
  });*/

  keyboardProxy.on('refreshBorder.editor', function () {
    setTimeout(function () {
      if (texteditor.isCellEdited) {
        texteditor.refreshDimensions(instance, row, col, keyboardProxy);
      }
    }, 0);
  });

  keyboardProxy.on("keydown.editor", function (event) {
    var ctrlDown = (event.ctrlKey || event.metaKey) && !event.altKey; //catch CTRL but not right ALT (which in some systems triggers ALT+CTRL)
    if (Handsontable.helper.isPrintableChar(event.keyCode)) {
      if (!texteditor.isCellEdited && !ctrlDown) { //disregard CTRL-key shortcuts
        texteditor.beginEditing(instance, null, row, col, prop, keyboardProxy);
        event.stopImmediatePropagation();
      }
      else if (ctrlDown) {
        if (texteditor.isCellEdited && event.keyCode === 65) { //CTRL + A
          event.stopPropagation();
        }
        else if (texteditor.isCellEdited && event.keyCode === 88 && $.browser.opera) { //CTRL + X
          event.stopPropagation();
        }
        else if (texteditor.isCellEdited && event.keyCode === 86 && $.browser.opera) { //CTRL + V
          event.stopPropagation();
        }
      }
      return;
    }

    if (texteditor.isCellEdited && (event.keyCode === 17 || event.keyCode === 224 || event.keyCode === 91 || event.keyCode === 93)) {
      //when CTRL is pressed and cell is edited, don't prepare selectable text in textarea
      event.stopPropagation();
      return;
    }

    switch (event.keyCode) {
      case 38: /* arrow up */
        if (texteditor.isCellEdited) {
          texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, false);
        }
        break;

      case 9: /* tab */
        if (texteditor.isCellEdited) {
          texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, false);
        }
        event.preventDefault();
        break;

      case 39: /* arrow right */
        if (texteditor.isCellEdited) {
          if (texteditor.getCaretPosition(keyboardProxy) === keyboardProxy.val().length) {
            texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, false);

          }
          else {
            event.stopPropagation();
          }
        }
        break;

      case 37: /* arrow left */
        if (texteditor.isCellEdited) {
          if (texteditor.getCaretPosition(keyboardProxy) === 0) {
            texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, false);
          }
          else {
            event.stopPropagation();
          }
        }
        break;

      case 8: /* backspace */
      case 46: /* delete */
        if (texteditor.isCellEdited) {
          event.stopPropagation();
        }
        break;

      case 40: /* arrow down */
        if (texteditor.isCellEdited) {
          texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, false);
        }
        break;

      case 27: /* ESC */
        if (texteditor.isCellEdited) {
          instance.destroyEditor(true);
          event.stopPropagation();
        }
        break;

      case 113: /* F2 */
        if (!texteditor.isCellEdited) {
          texteditor.beginEditing(instance, null, row, col, prop, keyboardProxy, true); //show edit field
          event.stopPropagation();
          event.preventDefault(); //prevent Opera from opening Go to Page dialog
        }
        break;

      case 13: /* return/enter */
        if (texteditor.isCellEdited) {
          var selected = instance.getSelected();
          var isMultipleSelection = !(selected[0] === selected[2] && selected[1] === selected[3]);
          if ((event.ctrlKey && !isMultipleSelection) || event.altKey) { //if ctrl+enter or alt+enter, add new line
            keyboardProxy.val(keyboardProxy.val() + '\n');
            keyboardProxy[0].focus();
            event.stopPropagation();
          }
          else {
            texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, false, ctrlDown);
          }
        }
        else if (instance.getSettings().enterBeginsEditing) {
          if ((ctrlDown && !selection.isMultiple()) || event.altKey) { //if ctrl+enter or alt+enter, add new line
            texteditor.beginEditing(instance, null, row, col, prop, keyboardProxy, true, '\n'); //show edit field
          }
          else {
            texteditor.beginEditing(instance, null, row, col, prop, keyboardProxy, true); //show edit field
          }
          event.stopPropagation();
        }
        event.preventDefault(); //don't add newline to field
        break;

      case 36: /* home */
        if (texteditor.isCellEdited) {
          event.stopPropagation();
        }
        break;

      case 35: /* end */
        if (texteditor.isCellEdited) {
          event.stopPropagation();
        }
        break;
    }
  });

  function onDblClick() {
    keyboardProxy[0].focus();
    texteditor.beginEditing(instance, null, row, col, prop, keyboardProxy, true);
  }

  instance.view.wt.update('onCellDblClick', onDblClick);

  return function (isCancelled) {
    texteditor.triggerOnlyByDestroyer = false;
    texteditor.finishEditing(instance, null, row, col, prop, keyboardProxy, isCancelled);
  }
};
function isAutoComplete(keyboardProxy) {
  var typeahead = keyboardProxy.data("typeahead");
  if (typeahead && typeahead.$menu.is(":visible")) {
    return typeahead;
  }
  else {
    return false;
  }
}

/**
 * Autocomplete editor
 * @param {Object} instance Handsontable instance
 * @param {Element} td Table cell where to render
 * @param {Number} row
 * @param {Number} col
 * @param {String|Number} prop Row object property name
 * @param {Object} keyboardProxy jQuery element of keyboard proxy that contains current editing value
 * @param {Object} cellProperties Cell properites (shared by cell renderer and editor)
 */
Handsontable.AutocompleteEditor = function (instance, td, row, col, prop, keyboardProxy, cellProperties) {
  var typeahead = keyboardProxy.data('typeahead')
    , i
    , j
    , dontHide = false;

  if (!typeahead) {
    keyboardProxy.typeahead();
    typeahead = keyboardProxy.data('typeahead');
    typeahead._show = typeahead.show;
    typeahead._hide = typeahead.hide;
    typeahead._render = typeahead.render;
    typeahead._highlighter = typeahead.highlighter;
  }
  else {
    typeahead.$menu.off(); //remove previous typeahead bindings
    keyboardProxy.off(); //remove previous typeahead bindings. Removing this will cause prepare to register 2 keydown listeners in typeahead
    typeahead.listen(); //add typeahead bindings
  }

  typeahead.minLength = 0;
  typeahead.highlighter = typeahead._highlighter;

  typeahead.show = function () {
    if (keyboardProxy.parent().hasClass('htHidden')) {
      return;
    }
    return typeahead._show.call(this);
  };

  typeahead.hide = function () {
    if (!dontHide) {
      dontHide = false; //set to true by dblclick handler, otherwise appears and disappears immediately after double click
      return typeahead._hide.call(this);
    }
  };

  typeahead.lookup = function () {
    var items;
    this.query = this.$element.val();
    items = $.isFunction(this.source) ? this.source(this.query, $.proxy(this.process, this)) : this.source;
    return items ? this.process(items) : this;
  };

  typeahead.matcher = function () {
    return true;
  };

  typeahead.select = function () {
    var val = this.$menu.find('.active').attr('data-value') || keyboardProxy.val();
    destroyer(true);
    instance.setDataAtCell(row, prop, typeahead.updater(val));
    return this.hide();
  };

  typeahead.render = function (items) {
    typeahead._render.call(this, items);
    if (!cellProperties.strict) {
      this.$menu.find('li:eq(0)').removeClass('active');
    }
    return this;
  };

  /* overwrite typeahead options and methods (matcher, sorter, highlighter, updater, etc) if provided in cellProperties */
  for (i in cellProperties) {
    if (cellProperties.hasOwnProperty(i)) {
      if (i === 'options') {
        for (j in cellProperties.options) {
          if (cellProperties.options.hasOwnProperty(j)) {
            typeahead.options[j] = cellProperties.options[j];
          }
        }
      }
      else {
        typeahead[i] = cellProperties[i];
      }
    }
  }

  var wasDestroyed = false;

  keyboardProxy.on("keydown.editor", function (event) {
    switch (event.keyCode) {
      case 27: /* ESC */
        dontHide = false;
        break;

      case 37: /* arrow left */
      case 39: /* arrow right */
      case 38: /* arrow up */
      case 40: /* arrow down */
      case 9: /* tab */
      case 13: /* return/enter */
        if (!keyboardProxy.parent().hasClass('htHidden')) {
          event.stopImmediatePropagation();
        }
        event.preventDefault();
    }
  });

  keyboardProxy.on("keyup.editor", function (event) {
      switch (event.keyCode) {
        case 9: /* tab */
        case 13: /* return/enter */
          if (!wasDestroyed && !isAutoComplete(keyboardProxy)) {
            var ev = $.Event('keyup');
            ev.keyCode = 113; //113 triggers lookup, in contrary to 13 or 9 which only trigger hide
            keyboardProxy.trigger(ev);
          }
          else {
            setTimeout(function () { //so pressing enter will move one row down after change is applied by 'select' above
              var ev = $.Event('keydown');
              ev.keyCode = event.keyCode;
              keyboardProxy.parent().trigger(ev);
            }, 10);
          }
          break;

        default:
          if (!wasDestroyed && !Handsontable.helper.isPrintableChar(event.keyCode)) { //otherwise Del or F12 would open suggestions list
            event.stopImmediatePropagation();
          }
      }
    }
  );

  var textDestroyer = Handsontable.TextEditor(instance, td, row, col, prop, keyboardProxy, cellProperties);

  function onDblClick() {
    keyboardProxy[0].focus();
    texteditor.beginEditing(instance, null, row, col, prop, keyboardProxy, true);
    dontHide = true;
    setTimeout(function () { //otherwise is misaligned in IE9
      keyboardProxy.data('typeahead').lookup();
    }, 1);
  }

  instance.view.wt.update('onCellDblClick', onDblClick); //no need to destroy it here because it will be destroyed by TextEditor destroyer

  var destroyer = function (isCancelled) {
    wasDestroyed = true;
    keyboardProxy.off(); //remove typeahead bindings
    textDestroyer(isCancelled);
    dontHide = false;
    if (isAutoComplete(keyboardProxy)) {
      isAutoComplete(keyboardProxy).hide();
    }
  };

  return destroyer;
};
function toggleCheckboxCell(instance, row, prop, cellProperties) {
  if (Handsontable.helper.stringify(instance.getDataAtCell(row, prop)) === Handsontable.helper.stringify(cellProperties.checkedTemplate)) {
    instance.setDataAtCell(row, prop, cellProperties.uncheckedTemplate);
  }
  else {
    instance.setDataAtCell(row, prop, cellProperties.checkedTemplate);
  }
}

/**
 * Checkbox editor
 * @param {Object} instance Handsontable instance
 * @param {Element} td Table cell where to render
 * @param {Number} row
 * @param {Number} col
 * @param {String|Number} prop Row object property name
 * @param {Object} keyboardProxy jQuery element of keyboard proxy that contains current editing value
 * @param {Object} cellProperties Cell properites (shared by cell renderer and editor)
 */
Handsontable.CheckboxEditor = function (instance, td, row, col, prop, keyboardProxy, cellProperties) {
  if (typeof cellProperties === "undefined") {
    cellProperties = {};
  }
  if (typeof cellProperties.checkedTemplate === "undefined") {
    cellProperties.checkedTemplate = true;
  }
  if (typeof cellProperties.uncheckedTemplate === "undefined") {
    cellProperties.uncheckedTemplate = false;
  }

  keyboardProxy.on("keydown.editor", function (event) {
    var ctrlDown = (event.ctrlKey || event.metaKey) && !event.altKey; //catch CTRL but not right ALT (which in some systems triggers ALT+CTRL)
    if (!ctrlDown && Handsontable.helper.isPrintableChar(event.keyCode)) {
      toggleCheckboxCell(instance, row, prop, cellProperties);
      event.stopPropagation();
    }
  });

  function onDblClick() {
    toggleCheckboxCell(instance, row, prop, cellProperties);
  }

  instance.view.wt.update('onCellDblClick', onDblClick);

  return function () {
    keyboardProxy.off(".editor");
    instance.view.wt.update('onCellDblClick', null);
  }
};
Handsontable.AutocompleteCell = {
  renderer: Handsontable.AutocompleteRenderer,
  editor: Handsontable.AutocompleteEditor
};

Handsontable.CheckboxCell = {
  renderer: Handsontable.CheckboxRenderer,
  editor: Handsontable.CheckboxEditor
};

Handsontable.TextCell = {
  renderer: Handsontable.TextRenderer,
  editor: Handsontable.TextEditor
};
Handsontable.PluginHooks = {
  hooks: {
    beforeInit: [],
    afterInit: [],
    afterLoadData: [],
    beforeRender: [],
    afterRender: [],
    beforeGet: [],
    beforeSet: [],
    afterGetCellMeta: [],
    afterGetColHeader: [],
    afterGetColWidth: [],
    walkontableConfig: []
  },

  push: function (key, fn) {
    this.hooks[key].push(fn);
  },

  unshift: function (key, fn) {
    this.hooks[key].unshift(fn);
  },

  run: function (instance, key, p1, p2, p3, p4, p5) {
    //performance considerations - http://jsperf.com/call-vs-apply-for-a-plugin-architecture
    for (var i = 0, ilen = this.hooks[key].length; i < ilen; i++) {
      this.hooks[key][i].call(instance, p1, p2, p3, p4, p5);
    }
  }
};

Handsontable.PluginModifiers = {
  modifiers: {
    col: []
  },

  push: function (key, fn) {
    this.modifiers[key].push(fn);
  },

  unshift: function (key, fn) {
    this.modifiers[key].unshift(fn);
  },

  run: function (instance, key, p1, p2, p3, p4, p5) {
    for (var i = 0, ilen = this.modifiers[key].length; i < ilen; i++) {
      p1 = this.modifiers[key][i].call(instance, p1, p2, p3, p4, p5);
    }
    return p1;
  }
};
/**
 * This plugin determines the optimal column size for the data that's inside it
 * @constructor
 */
function HandsontableAutoColumnSize() {
  var that = this
    , instance
    , tmp
    , $tmp
    , tmpTbody
    , tmpThead
    , sampleCount = 5; //number of samples to take of each value length

  this.beforeInit = function () {
    this.autoColumnWidths = [];
  };

  this.determineColumnWidth = function (col) {
    if (!tmp) {
      tmp = document.createElement('DIV');
      tmp.style.position = 'absolute';
      tmp.style.top = '0';
      tmp.style.left = '0';
      tmp.style.display = 'none';

      tmpTbody = $('<table><thead><tr><td></td></tr></thead></table>')[0];
      tmp.appendChild(tmpTbody);

      tmp.appendChild(document.createElement('BR'));

      tmpThead = $('<table><tbody><tr><td></td></tr></tbody></table>')[0];
      tmp.appendChild(tmpThead);

      document.body.appendChild(tmp);
      $tmp = $(tmp);
    }

    var rows = instance.countRows();
    var samples = {};
    for (var r = 0; r < rows; r++) {
      var value = Handsontable.helper.stringify(instance.getDataAtCell(r, col));
      var len = value.length;
      if (!samples[len]) {
        samples[len] = {
          needed: sampleCount,
          strings: []
        };
      }
      if (samples[len].needed) {
        samples[len].strings.push(value);
        samples[len].needed--;
      }
    }

    var settings = instance.getSettings();
    if (settings.colHeaders) {
      instance.getColHeader(col, tmpThead.firstChild.firstChild.firstChild); //TH innerHTML
    }

    var txt = '';
    for (var i in samples) {
      if (samples.hasOwnProperty(i)) {
        for (var j = 0, jlen = samples[i].strings.length; j < jlen; j++) {
          txt += samples[i].strings[j] + '<br>';
        }
      }
    }
    tmpTbody.firstChild.firstChild.firstChild.innerHTML = txt; //TD innerHTML

    tmp.style.display = 'block';
    var width = $tmp.outerWidth();
    tmp.style.display = 'none';
    return width;
  };

  this.determineColumnsWidth = function () {
    instance = this;
    var settings = this.getSettings();
    if (settings.autoColumnSize || !settings.colWidths) {
      var cols = this.countCols();
      for (var c = 0; c < cols; c++) {
        this.autoColumnWidths[c] = that.determineColumnWidth(c);
      }
    }
  };

  this.getColWidth = function (col, response) {
    if (this.autoColumnWidths[col] && this.autoColumnWidths[col] > response.width) {
      response.width = this.autoColumnWidths[col];
    }
  };
}
var htAutoColumnSize = new HandsontableAutoColumnSize();

Handsontable.PluginHooks.push('beforeInit', htAutoColumnSize.beforeInit);
Handsontable.PluginHooks.push('beforeRender', htAutoColumnSize.determineColumnsWidth);
Handsontable.PluginHooks.push('afterGetColWidth', htAutoColumnSize.getColWidth);

/**
 * This plugin sorts the view by a column (but does not sort the data source!)
 * @constructor
 */
function HandsontableColumnSorting() {
  var plugin = this;
  var sortingEnabled;

  this.afterInit = function () {
    var instance = this;
    if (this.getSettings().columnSorting) {
      this.sortIndex = [];
      this.rootElement.on('click.handsontable', '.columnSorting', function (e) {
        var $target = $(e.target);
        if ($target.is('.columnSorting')) {
          var col = $target.closest('th').index();
          if (instance.getSettings().rowHeaders) {
            col--;
          }
          if (instance.sortColumn === col) {
            instance.sortOrder = !instance.sortOrder;
          }
          else {
            instance.sortColumn = col;
            instance.sortOrder = true;
          }
          plugin.sort.call(instance);
          instance.render();
        }
      });
    }
  };

  this.sort = function () {
    sortingEnabled = false;
    var instance = this;
    this.sortIndex.length = 0;
    //var data = this.getData();
    for (var i = 0, ilen = this.countRows(); i < ilen; i++) {
      //this.sortIndex.push([i, data[i][this.sortColumn]]);
      this.sortIndex.push([i, instance.getDataAtCell(i, this.sortColumn)]);
    }
    this.sortIndex.sort(function (a, b) {
      if (a[1] === b[1]) {
        return 0;
      }
      if (a[1] === null) {
        return 1;
      }
      if (b[1] === null) {
        return -1;
      }
      if (a[1] < b[1]) return instance.sortOrder ? -1 : 1;
      if (a[1] > b[1]) return instance.sortOrder ? 1 : -1;
      return 0;
    });
    sortingEnabled = true;
  };

  this.translateRow = function (getVars) {
    if (sortingEnabled && this.sortIndex && this.sortIndex.length) {
      getVars.row = this.sortIndex[getVars.row][0];
    }
  };

  this.getColHeader = function (col, TH) {
    if (this.getSettings().columnSorting) {
      $(TH).find('span.colHeader').addClass('columnSorting');
    }
  };
}
var htSortColumn = new HandsontableColumnSorting();

Handsontable.PluginHooks.push('afterInit', htSortColumn.afterInit);
Handsontable.PluginHooks.push('beforeGet', htSortColumn.translateRow);
Handsontable.PluginHooks.push('beforeSet', htSortColumn.translateRow);
Handsontable.PluginHooks.push('afterGetColHeader', htSortColumn.getColHeader);
function createContextMenu() {
  var instance = this
    , defaultOptions = {
      selector: "#" + instance.rootElement.attr('id') + ' table, #' + instance.rootElement.attr('id') + ' div',
      trigger: 'right',
      callback: onContextClick
    },
    allItems = {
      "row_above": {name: "Insert row above", disabled: isDisabled},
      "row_below": {name: "Insert row below", disabled: isDisabled},
      "hsep1": "---------",
      "col_left": {name: "Insert column on the left", disabled: isDisabled},
      "col_right": {name: "Insert column on the right", disabled: isDisabled},
      "hsep2": "---------",
      "remove_row": {name: "Remove row", disabled: isDisabled},
      "remove_col": {name: "Remove column", disabled: isDisabled},
      "hsep3": "---------",
      "undo": {name: "Undo", disabled: function () {
        return !instance.isUndoAvailable();
      }},
      "redo": {name: "Redo", disabled: function () {
        return !instance.isRedoAvailable();
      }}
    }
    , options = {}
    , i
    , ilen
    , settings = instance.getSettings();

  function onContextClick(key) {
    var corners = instance.getSelected(); //[top left row, top left col, bottom right row, bottom right col]

    if(!corners) {
      return; //needed when there are 2 grids on a page
    }

    switch (key) {
      case "row_above":
        instance.alter("insert_row", corners[0]);
        break;

      case "row_below":
        instance.alter("insert_row", corners[2] + 1);
        break;

      case "col_left":
        instance.alter("insert_col", corners[1]);
        break;

      case "col_right":
        instance.alter("insert_col", corners[3] + 1);
        break;

      case "remove_row":
        instance.alter(key, corners[0], corners[2]);
        break;

      case "remove_col":
        instance.alter(key, corners[1], corners[3]);
        break;

      case "undo":
        instance.undo();
        break;

      case "redo":
        instance.redo();
        break;
    }
  }

  function isDisabled(key) {
    //TODO rewrite
    /*if (instance.blockedCols.main.find('th.htRowHeader.active').length && (key === "remove_col" || key === "col_left" || key === "col_right")) {
     return true;
     }
     else if (instance.blockedRows.main.find('th.htColHeader.active').length && (key === "remove_row" || key === "row_above" || key === "row_below")) {
     return true;
     }
     else*/
    if (instance.countRows() >= instance.getSettings().maxRows && (key === "row_above" || key === "row_below")) {
      return true;
    }
    else if (instance.countCols() >= instance.getSettings().maxCols && (key === "col_left" || key === "col_right")) {
      return true;
    }
    else {
      return false;
    }
  }

  if (!settings.contextMenu) {
    return;
  }
  else if (settings.contextMenu === true) { //contextMenu is true
    options.items = allItems;
  }
  else if (Object.prototype.toString.apply(settings.contextMenu) === '[object Array]') { //contextMenu is an array
    options.items = {};
    for (i = 0, ilen = settings.contextMenu.length; i < ilen; i++) {
      var key = settings.contextMenu[i];
      if (typeof allItems[key] === 'undefined') {
        throw new Error('Context menu key "' + key + '" is not recognised');
      }
      options.items[key] = allItems[key];
    }
  }
  else if (Object.prototype.toString.apply(settings.contextMenu) === '[object Object]') { //contextMenu is an options object as defined in http://medialize.github.com/jQuery-contextMenu/docs.html
    options = settings.contextMenu;
    if (options.items) {
      for (i in options.items) {
        if (options.items.hasOwnProperty(i) && allItems[i]) {
          if (typeof options.items[i] === 'string') {
            options.items[i] = allItems[i];
          }
          else {
            options.items[i] = $.extend(true, allItems[i], options.items[i]);
          }
        }
      }
    }
    else {
      options.items = allItems;
    }

    if (options.callback) {
      var handsontableCallback = defaultOptions.callback;
      var customCallback = options.callback;
      options.callback = function (key, options) {
        handsontableCallback(key, options);
        customCallback(key, options);
      }
    }
  }

  if (!instance.rootElement.attr('id')) {
    throw new Error("Handsontable container must have an id");
  }

  $.contextMenu($.extend(true, defaultOptions, options));
}

Handsontable.PluginHooks.push('afterInit', createContextMenu);
/**
 * This plugin adds support for legacy features, deprecated APIs, etc.
 */

/**
 * Support for old autocomplete syntax
 * For old syntax, see: https://github.com/warpech/jquery-handsontable/blob/8c9e701d090ea4620fe08b6a1a048672fadf6c7e/README.md#defining-autocomplete
 */
Handsontable.PluginHooks.push('afterGetCellMeta', function (row, col, cellProperties) {
  var settings = this.getSettings(), data = this.getData(), i, ilen, a;
  if (settings.autoComplete) {
    for (i = 0, ilen = settings.autoComplete.length; i < ilen; i++) {
      if (settings.autoComplete[i].match(row, col, data)) {
        if (typeof cellProperties.type === 'undefined') {
          cellProperties.type = Handsontable.AutocompleteCell;
        }
        else {
          if (typeof cellProperties.type.renderer === 'undefined') {
            cellProperties.type.renderer = Handsontable.AutocompleteCell.renderer;
          }
          if (typeof cellProperties.type.editor === 'undefined') {
            cellProperties.type.editor = Handsontable.AutocompleteCell.editor;
          }
        }
        for (a in settings.autoComplete[i]) {
          if (settings.autoComplete[i].hasOwnProperty(a) && a !== 'match' && typeof cellProperties[i] === 'undefined') {
            if(a === 'source') {
              cellProperties[a] = settings.autoComplete[i][a](row, col);
            }
            else {
              cellProperties[a] = settings.autoComplete[i][a];
            }
          }
        }
        break;
      }
    }
  }
});
function HandsontableManualColumnMove() {
  var instance
    , pressed
    , startCol
    , endCol
    , startX
    , startOffset;

  var $ghost = $('<div class="ghost"></div>');
  $ghost.css({
    position: 'absolute',
    top: '25px',
    left: 0,
    width: '10px',
    height: '10px',
    backgroundColor: '#CCC',
    opacity: 0.7
  });

  $(document).mousemove(function (e) {
    if (pressed) {
      $ghost[0].style.left = startOffset + e.pageX - startX + 6 + 'px';
      if ($ghost[0].style.display === 'none') {
        $ghost[0].style.display = 'block';
      }
    }
  });

  $(document).mouseup(function () {
    if (pressed) {
      if (startCol < endCol) {
        endCol--;
      }
      if (instance.getSettings().rowHeaders) {
        startCol--;
        endCol--;
      }
      instance.manualColumnPositions.splice(endCol, 0, instance.manualColumnPositions.splice(startCol, 1)[0]);
      $('.manualColumnMover.active').removeClass('active');
      pressed = false;
      instance.forceFullRender = true;
      instance.view.render(); //updates all
      $ghost[0].style.display = 'none';
    }
  });

  this.beforeInit = function () {
    this.manualColumnPositions = [];
  };

  this.afterInit = function () {
    if (this.getSettings().manualColumnMove) {
      var that = this;
      this.rootElement.on('mousedown.handsontable', '.manualColumnMover', function (e) {
        instance = that;

        var $resizer = $(e.target);
        var th = $resizer.closest('th');
        startCol = th.index();
        pressed = true;
        startX = e.pageX;

        var $table = that.rootElement.find('.htCore');
        $ghost.appendTo($table.parent());
        $ghost.width($resizer.parent().width());
        $ghost.height($table.height());
        startOffset = parseInt(th.offset().left - $table.offset().left);
        $ghost[0].style.left = startOffset + 6 + 'px';
      });
      this.rootElement.on('mouseenter.handsontable', 'td, th', function (e) {
        if (pressed) {
          $('.manualColumnMover.active').removeClass('active');
          var $ths = that.rootElement.find('thead th');
          endCol = $(this).index();
          var $hover = $ths.eq(endCol).find('.manualColumnMover').addClass('active');
          $ths.not($hover).removeClass('active');
        }
      });
    }
  };

  this.modifyCol = function (col) {
    //TODO test performance: http://jsperf.com/object-wrapper-vs-primitive/2
    if (this.getSettings().manualColumnMove) {
      if (typeof this.manualColumnPositions[col] === 'undefined') {
        this.manualColumnPositions[col] = col;
      }
      return this.manualColumnPositions[col];
    }
    return col;
  };

  this.getColHeader = function (col, TH) {
    if (this.getSettings().manualColumnMove) {
      var DIV = document.createElement('DIV');
      DIV.className = 'manualColumnMover';
      TH.firstChild.appendChild(DIV);
    }
  };
}
var htManualColumnMove = new HandsontableManualColumnMove();

Handsontable.PluginHooks.push('beforeInit', htManualColumnMove.beforeInit);
Handsontable.PluginHooks.push('afterInit', htManualColumnMove.afterInit);
Handsontable.PluginHooks.push('afterGetColHeader', htManualColumnMove.getColHeader);
Handsontable.PluginModifiers.push('col', htManualColumnMove.modifyCol);

function HandsontableManualColumnResize() {
  var pressed
    , currentCol
    , currentWidth
    , instance
    , start
    , startX
    , startWidth
    , startOffset;

  var $line = $('<div class="manualColumnResizerLine"><div class="manualColumnResizer"></div></div>');
  $line.css({
    position: 'absolute',
    top: 0,
    left: 0,
    width: 0,
    borderRight: '1px dashed #777'
  });

  $(document).mousemove(function (e) {
    if (pressed) {
      currentWidth = startWidth + (e.pageX - startX);
      setManualSize(currentCol, currentWidth); //save col width
      $line[0].style.left = startOffset + currentWidth - 1 + 'px';
      if ($line[0].style.display === 'none') {
        $line[0].style.display = 'block';
      }
    }
  });

  $(document).mouseup(function () {
    if (pressed) {
      $('.manualColumnResizer.active').removeClass('active');
      pressed = false;
      instance.forceFullRender = true;
      instance.view.render(); //updates all
      $line[0].style.display = 'none';
    }
  });

  $(document).dblclick(function (e) {
    if ($(e.target).is('.manualColumnResizer')) {
      setManualSize(currentCol, htAutoColumnSize.determineColumnWidth.call(instance, currentCol));
    }
  });

  this.beforeInit = function () {
    this.manualColumnWidths = [];
  };

  this.afterInit = function () {
    if (this.getSettings().manualColumnResize) {
      var that = this;
      this.rootElement.on('mousedown.handsontable', '.manualColumnResizer', function (e) {
        instance = that;
        var $resizer = $(e.target);
        currentCol = $resizer.attr('rel');
        start = that.rootElement.find('col').eq($resizer.parent().parent().index());
        pressed = true;
        startX = e.pageX;
        startWidth = start.width();
        currentWidth = startWidth;
        $resizer.addClass('active');

        var $table = that.rootElement.find('.htCore');
        $line.appendTo($table.parent()).height($table.height());
        startOffset = parseInt($resizer.parent().parent().offset().left - $table.offset().left);
        $line[0].style.left = startOffset + currentWidth - 1 + 'px';
      });
    }
  };

  var setManualSize = function (col, width) {
    width = Math.max(width, 20);
    width = Math.min(width, 500);
    instance.manualColumnWidths[col] = width;
  };

  this.getColHeader = function (col, TH) {
    if (this.getSettings().manualColumnResize) {
      var DIV = document.createElement('DIV');
      DIV.className = 'manualColumnResizer';
      $(DIV).attr('rel', col);
      TH.firstChild.appendChild(DIV);
    }
  };

  this.getColWidth = function (col, response) {
    if (this.getSettings().manualColumnResize && this.manualColumnWidths[col]) {
      response.width = this.manualColumnWidths[col];
    }
  };
}
var htManualColumnResize = new HandsontableManualColumnResize();

Handsontable.PluginHooks.push('beforeInit', htManualColumnResize.beforeInit);
Handsontable.PluginHooks.push('afterInit', htManualColumnResize.afterInit);
Handsontable.PluginHooks.push('afterGetColHeader', htManualColumnResize.getColHeader);
Handsontable.PluginHooks.push('afterGetColWidth', htManualColumnResize.getColWidth);

/*
 * jQuery.fn.autoResize 1.1+
 * --
 * https://github.com/warpech/jQuery.fn.autoResize
 *
 * This fork differs from others in a way that it autoresizes textarea in 2-dimensions (horizontally and vertically).
 * It was originally forked from alexbardas's repo but maybe should be merged with dpashkevich's repo in future.
 *
 * originally forked from:
 * https://github.com/jamespadolsey/jQuery.fn.autoResize
 * which is now located here:
 * https://github.com/alexbardas/jQuery.fn.autoResize
 * though the mostly maintained for is here:
 * https://github.com/dpashkevich/jQuery.fn.autoResize/network
 *
 * --
 * This program is free software. It comes without any warranty, to
 * the extent permitted by applicable law. You can redistribute it
 * and/or modify it under the terms of the Do What The Fuck You Want
 * To Public License, Version 2, as published by Sam Hocevar. See
 * http://sam.zoy.org/wtfpl/COPYING for more details. */

(function($){

  autoResize.defaults = {
    onResize: function(){},
    animate: {
      duration: 200,
      complete: function(){}
    },
    extraSpace: 50,
    minHeight: 'original',
    maxHeight: 500,
    minWidth: 'original',
    maxWidth: 500
  };

  autoResize.cloneCSSProperties = [
    'lineHeight', 'textDecoration', 'letterSpacing',
    'fontSize', 'fontFamily', 'fontStyle', 'fontWeight',
    'textTransform', 'textAlign', 'direction', 'wordSpacing', 'fontSizeAdjust',
    'padding'
  ];

  autoResize.cloneCSSValues = {
    position: 'absolute',
    top: -9999,
    left: -9999,
    opacity: 0,
    overflow: 'hidden',
    border: '1px solid black',
    padding: '0.49em' //this must be about the width of caps W character
  };

  autoResize.resizableFilterSelector = 'textarea,input:not(input[type]),input[type=text],input[type=password]';

  autoResize.AutoResizer = AutoResizer;

  $.fn.autoResize = autoResize;

  function autoResize(config) {
    this.filter(autoResize.resizableFilterSelector).each(function(){
      new AutoResizer( $(this), config );
    });
    return this;
  }

  function AutoResizer(el, config) {

    if(this.clones) return;

    this.config = $.extend({}, autoResize.defaults, config);

    this.el = el;

    this.nodeName = el[0].nodeName.toLowerCase();

    this.previousScrollTop = null;

    if (config.maxWidth === 'original') config.maxWidth = el.width();
    if (config.minWidth === 'original') config.minWidth = el.width();
    if (config.maxHeight === 'original') config.maxHeight = el.height();
    if (config.minHeight === 'original') config.minHeight = el.height();

    if (this.nodeName === 'textarea') {
      el.css({
        resize: 'none',
        overflowY: 'hidden'
      });
    }

    el.data('AutoResizer', this);

    this.createClone();
    this.injectClone();
    this.bind();

  }

  AutoResizer.prototype = {

    bind: function() {

      var check = $.proxy(function(){
        this.check();
        return true;
      }, this);

      this.unbind();

      this.el
        .bind('keyup.autoResize', check)
        //.bind('keydown.autoResize', check)
        .bind('change.autoResize', check);

      this.check(null, true);

    },

    unbind: function() {
      this.el.unbind('.autoResize');
    },

    createClone: function() {

      var el = this.el,
        self = this,
        config = this.config;

      this.clones = $();

      if (config.minHeight !== 'original' || config.maxHeight !== 'original') {
        this.hClone = el.clone().height('auto');
        this.clones = this.clones.add(this.hClone);
      }
      if (config.minWidth !== 'original' || config.maxWidth !== 'original') {
        this.wClone = $('<div/>').width('auto').css({
          whiteSpace: 'nowrap',
          'float': 'left'
        });
        this.clones = this.clones.add(this.wClone);
      }

      $.each(autoResize.cloneCSSProperties, function(i, p){
        self.clones.css(p, el.css(p));
      });

      this.clones
        .removeAttr('name')
        .removeAttr('id')
        .attr('tabIndex', -1)
        .css(autoResize.cloneCSSValues);

    },

    check: function(e, immediate) {

      var config = this.config,
        wClone = this.wClone,
        hClone = this.hClone,
        el = this.el,
        value = el.val();

      if (wClone) {

        wClone.text(value);

        // Calculate new width + whether to change
        var cloneWidth = wClone.outerWidth(),
          newWidth = (cloneWidth + config.extraSpace) >= config.minWidth ?
            cloneWidth + config.extraSpace : config.minWidth,
          currentWidth = el.width();

        newWidth = Math.min(newWidth, config.maxWidth);

        if (
          (newWidth < currentWidth && newWidth >= config.minWidth) ||
            (newWidth >= config.minWidth && newWidth <= config.maxWidth)
          ) {

          config.onResize.call(el);

          el.scrollLeft(0);

          config.animate && !immediate ?
            el.stop(1,1).animate({
              width: newWidth
            }, config.animate)
            : el.width(newWidth);

        }

      }

      if (hClone) {

        if (newWidth) {
          hClone.width(newWidth);
        }

        hClone.height(0).val(value).scrollTop(10000);

        var scrollTop = hClone[0].scrollTop + config.extraSpace;

        // Don't do anything if scrollTop hasen't changed:
        if (this.previousScrollTop === scrollTop) {
          return;
        }

        this.previousScrollTop = scrollTop;

        if (scrollTop >= config.maxHeight) {
          el.css('overflowY', '');
          return;
        }

        el.css('overflowY', 'hidden');

        if (scrollTop < config.minHeight) {
          scrollTop = config.minHeight;
        }

        config.onResize.call(el);

        // Either animate or directly apply height:
        config.animate && !immediate ?
          el.stop(1,1).animate({
            height: scrollTop
          }, config.animate)
          : el.height(scrollTop);
      }
    },

    destroy: function() {
      this.unbind();
      this.el.removeData('AutoResizer');
      this.clones.remove();
      delete this.el;
      delete this.hClone;
      delete this.wClone;
      delete this.clones;
    },

    injectClone: function() {
      (
        autoResize.cloneContainer ||
          (autoResize.cloneContainer = $('<arclones/>').appendTo('body'))
        ).empty().append(this.clones); //this should be refactored so that a node is never cloned more than once
    }

  };

})(jQuery);
/**
 * SheetClip - Spreadsheet Clipboard Parser
 * version 0.2
 *
 * This tiny library transforms JavaScript arrays to strings that are pasteable by LibreOffice, OpenOffice,
 * Google Docs and Microsoft Excel.
 *
 * Copyright 2012, Marcin Warpechowski
 * Licensed under the MIT license.
 * http://github.com/warpech/sheetclip/
 */
/*jslint white: true*/
(function (global) {
  "use strict";

  function countQuotes(str) {
    return str.split('"').length - 1;
  }

  global.SheetClip = {
    parse: function (str) {
      var r, rlen, rows, arr = [], a = 0, c, clen, multiline, last;
      rows = str.split('\n');
      if (rows.length > 1 && rows[rows.length - 1] === '') {
        rows.pop();
      }
      for (r = 0, rlen = rows.length; r < rlen; r += 1) {
        rows[r] = rows[r].split('\t');
        for (c = 0, clen = rows[r].length; c < clen; c += 1) {
          if (!arr[a]) {
            arr[a] = [];
          }
          if (multiline && c === 0) {
            last = arr[a].length - 1;
            arr[a][last] = arr[a][last] + '\n' + rows[r][0];
            if (multiline && countQuotes(rows[r][0]) % 2 === 1) {
              multiline = false;
              arr[a][last] = arr[a][last].substring(0, arr[a][last].length - 1).replace(/""/g, '"');
            }
          }
          else {
            if (c === clen - 1 && rows[r][c].indexOf('"') === 0) {
              arr[a].push(rows[r][c].substring(1).replace(/""/g, '"'));
              multiline = true;
            }
            else {
              arr[a].push(rows[r][c].replace(/""/g, '"'));
              multiline = false;
            }
          }
        }
        if (!multiline) {
          a += 1;
        }
      }
      return arr;
    },

    stringify: function (arr) {
      var r, rlen, c, clen, str = '', val;
      for (r = 0, rlen = arr.length; r < rlen; r += 1) {
        for (c = 0, clen = arr[r].length; c < clen; c += 1) {
          if (c > 0) {
            str += '\t';
          }
          val = arr[r][c];
          if (typeof val === 'string') {
            if (val.indexOf('\n') > -1) {
              str += '"' + val.replace(/"/g, '""') + '"';
            }
            else {
              str += val;
            }
          }
          else if (val === null || val === void 0) { //void 0 resolves to undefined
            str += '';
          }
          else {
            str += val;
          }
        }
        str += '\n';
      }
      return str;
    }
  };
}(window));
/**
 * walkontable 0.1
 * 
 * Date: Wed Jan 23 2013 01:38:29 GMT+0100 (Central European Standard Time)
*/

function WalkontableBorder(instance, settings) {
  //reference to instance
  this.instance = instance;
  this.settings = settings;
  this.wtDom = new WalkontableDom();

  this.main = document.createElement("div");
  this.main.style.position = 'absolute';
  this.main.style.top = 0;
  this.main.style.left = 0;

  for (var i = 0; i < 5; i++) {
    var DIV = document.createElement('DIV');
    DIV.className = 'wtBorder ' + (settings.className || '');
    DIV.style.backgroundColor = settings.border.color;
    DIV.style.height = settings.border.width + 'px';
    DIV.style.width = settings.border.width + 'px';
    this.main.appendChild(DIV);
  }

  this.top = this.main.childNodes[0];
  this.left = this.main.childNodes[1];
  this.bottom = this.main.childNodes[2];
  this.right = this.main.childNodes[3];

  this.corner = this.main.childNodes[4];
  this.corner.className += ' corner';
  this.corner.style.width = '5px';
  this.corner.style.height = '5px';
  this.corner.style.border = '2px solid #FFF';

  this.disappear();
  instance.wtTable.hider.appendChild(this.main);
}

/**
 * Show border around one or many cells
 * @param {Array} corners
 */
WalkontableBorder.prototype.appear = function (corners) {
  var isMultiple, $from, $to, fromOffset, toOffset, containerOffset, top, minTop, left, minLeft, height, width;
  if (this.disabled) {
    return;
  }

  var offsetRow = this.instance.getSetting('offsetRow')
    , offsetColumn = this.instance.getSetting('offsetColumn')
    , displayRows = this.instance.getSetting('displayRows')
    , displayColumns = this.instance.getSetting('displayColumns');

  var hideTop = false, hideLeft = false, hideBottom = false, hideRight = false;

  if (displayRows !== null) {
    if (corners[0] > offsetRow + displayRows - 1 || corners[2] < offsetRow) {
      hideTop = hideLeft = hideBottom = hideRight = true;
    }
    else {
      if (corners[0] < offsetRow) {
        corners[0] = offsetRow;
        hideTop = true;
      }
      if (corners[2] > offsetRow + displayRows - 1) {
        corners[2] = offsetRow + displayRows - 1;
        hideBottom = true;
      }
    }
  }

  if (displayColumns !== null) {
    if (corners[1] > offsetColumn + displayColumns - 1 || corners[3] < offsetColumn) {
      hideTop = hideLeft = hideBottom = hideRight = true;
    }
    else {
      if (corners[1] < offsetColumn) {
        corners[1] = offsetColumn;
        hideLeft = true;
      }
      if (corners[3] > offsetColumn + displayColumns - 1) {
        corners[3] = offsetColumn + displayColumns - 1;
        hideRight = true;
      }
    }
  }

  if (hideTop + hideLeft + hideBottom + hideRight < 4) { //at least one border is not hidden
    isMultiple = (corners[0] !== corners[2] || corners[1] !== corners[3]);
    $from = $(this.instance.wtTable.getCell([corners[0], corners[1]]));
    $to = isMultiple ? $(this.instance.wtTable.getCell([corners[2], corners[3]])) : $from;
    fromOffset = this.wtDom.offset($from[0]);
    toOffset = isMultiple ? this.wtDom.offset($to[0]) : fromOffset;
    containerOffset = this.wtDom.offset(this.instance.wtTable.TABLE);

    minTop = fromOffset.top;
    height = toOffset.top + $to.outerHeight() - minTop;
    minLeft = fromOffset.left;
    width = toOffset.left + $to.outerWidth() - minLeft;

    top = minTop - containerOffset.top - 1;
    left = minLeft - containerOffset.left - 1;

    if (parseInt($from.css('border-top-width')) > 0) {
      top += 1;
      height -= 1;
    }
    if (parseInt($from.css('border-left-width')) > 0) {
      left += 1;
      width -= 1;
    }
  }

  if (hideTop) {
    this.top.style.display = 'none';
  }
  else {
    this.top.style.top = top + 'px';
    this.top.style.left = left + 'px';
    this.top.style.width = width + 'px';
    this.top.style.display = 'block';
  }

  if (hideLeft) {
    this.left.style.display = 'none';
  }
  else {
    this.left.style.top = top + 'px';
    this.left.style.left = left + 'px';
    this.left.style.height = height + 'px';
    this.left.style.display = 'block';
  }

  var delta = Math.floor(this.settings.border.width / 2);

  if (hideBottom) {
    this.bottom.style.display = 'none';
  }
  else {
    this.bottom.style.top = top + height - delta + 'px';
    this.bottom.style.left = left + 'px';
    this.bottom.style.width = width + 'px';
    this.bottom.style.display = 'block';
  }

  if (hideRight) {
    this.right.style.display = 'none';
  }
  else {
    this.right.style.top = top + 'px';
    this.right.style.left = left + width - delta + 'px';
    this.right.style.height = height + 1 + 'px';
    this.right.style.display = 'block';
  }

  if (hideBottom && hideRight || !this.hasSetting(this.settings.border.cornerVisible)) {
    this.corner.style.display = 'none';
  }
  else {
    this.corner.style.top = top + height - 4 + 'px';
    this.corner.style.left = left + width - 4 + 'px';
    this.corner.style.display = 'block';
  }
};

/**
 * Hide border
 */
WalkontableBorder.prototype.disappear = function () {
  this.top.style.display = 'none';
  this.left.style.display = 'none';
  this.bottom.style.display = 'none';
  this.right.style.display = 'none';
  this.corner.style.display = 'none';
};

WalkontableBorder.prototype.hasSetting = function (setting) {
  if (typeof setting === 'function') {
    return setting();
  }
  return !!setting;
};
function Walkontable(settings) {
  var originalHeaders = [];

  //bootstrap from settings
  this.wtSettings = new WalkontableSettings(this, settings);
  this.wtTable = new WalkontableTable(this);
  this.wtScroll = new WalkontableScroll(this);
  this.wtWheel = new WalkontableWheel(this);
  this.wtEvent = new WalkontableEvent(this);
  this.wtDom = new WalkontableDom();

  //find original headers
  if (this.wtTable.THEAD.childNodes.length && this.wtTable.THEAD.childNodes[0].childNodes.length) {
    for (var c = 0, clen = this.wtTable.THEAD.childNodes[0].childNodes.length; c < clen; c++) {
      originalHeaders.push(this.wtTable.THEAD.childNodes[0].childNodes[c].innerHTML);
    }
    if (!this.hasSetting('columnHeaders')) {
      this.update('columnHeaders', function (column, TH) {
        TH.innerHTML = originalHeaders[column];
      });
    }
  }

  //initialize selections
  this.selections = {};
  var selectionsSettings = this.getSetting('selections');
  if (selectionsSettings) {
    for (var i in selectionsSettings) {
      if (selectionsSettings.hasOwnProperty(i)) {
        this.selections[i] = new WalkontableSelection(this, selectionsSettings[i]);
      }
    }
  }

  this.drawn = false;
}

Walkontable.prototype.draw = function (selectionsOnly) {
  //this.instance.scrollViewport([this.instance.getSetting('offsetRow'), this.instance.getSetting('offsetColumn')]); //needed by WalkontableScroll -> remove row from the last scroll page should scroll viewport a row up if needed
  if (this.hasSetting('async')) {
    var that = this;
    that.drawFrame = setTimeout(function () {
      that._doDraw(selectionsOnly);
    }, 0);
  }
  else {
    this._doDraw(selectionsOnly);
  }
  return this;
};

Walkontable.prototype._doDraw = function (selectionsOnly) {
  selectionsOnly = selectionsOnly && this.getSetting('offsetRow') === this.lastOffsetRow && this.getSetting('offsetColumn') === this.lastOffsetColumn;
  this.lastOffsetRow = this.getSetting('offsetRow');
  this.lastOffsetColumn = this.getSetting('offsetColumn');
  this.wtTable.draw(selectionsOnly);
};

Walkontable.prototype.update = function (settings, value) {
  return this.wtSettings.update(settings, value);
};

Walkontable.prototype.scrollVertical = function (delta) {
  return this.wtScroll.scrollVertical(delta);
};

Walkontable.prototype.scrollHorizontal = function (delta) {
  return this.wtScroll.scrollHorizontal(delta);
};

Walkontable.prototype.scrollViewport = function (coords) {
  if (this.hasSetting('async')) {
    var that = this;
    clearTimeout(that.scrollFrame);
    that.scrollFrame = setTimeout(function () {
      that.wtScroll.scrollViewport(coords);
    }, 0);
  }
  else {
    this.wtScroll.scrollViewport(coords);
  }
  return this;
};

Walkontable.prototype.getViewport = function () {
  //TODO change it to draw values only (add this.wtTable.visibilityStartRow, this.wtTable.visibilityStartColumn)
  return [
    this.getSetting('offsetRow'),
    this.getSetting('offsetColumn'),
    this.wtTable.visibilityEdgeRow !== null ? this.wtTable.visibilityEdgeRow : this.getSetting('totalRows') - 1,
    this.wtTable.visibilityEdgeColumn !== null ? this.wtTable.visibilityEdgeColumn : this.getSetting('totalColumns') - 1
  ];
};

Walkontable.prototype.getSetting = function (key, param1, param2, param3) {
  return this.wtSettings.getSetting(key, param1, param2, param3);
};

Walkontable.prototype.hasSetting = function (key) {
  return this.wtSettings.has(key);
};
function WalkontableDom() {
}

//goes up the DOM tree (including given element) until it finds an element that matches the nodeName
WalkontableDom.prototype.closest = function (elem, nodeNames) {
  while (elem != null) {
    if (elem.nodeType === 1 && nodeNames.indexOf(elem.nodeName) > -1) {
      return elem;
    }
    elem = elem.parentNode;
  }
  return null;
};

WalkontableDom.prototype.prevSiblings = function (elem) {
  var out = [];
  while ((elem = elem.previousSibling) != null) {
    if (elem.nodeType === 1) {
      out.push(elem);
    }
  }
  return out;
};

//http://snipplr.com/view/3561/addclass-removeclass-hasclass/
WalkontableDom.prototype.hasClass = function (ele, cls) {
  return ele.className.match(new RegExp('(\\s|^)' + cls + '(\\s|$)'));
};

WalkontableDom.prototype.addClass = function (ele, cls) {
  if (!this.hasClass(ele, cls)) ele.className += " " + cls;
};

WalkontableDom.prototype.removeClass = function (ele, cls) {
  if (this.hasClass(ele, cls)) { //is this really needed?
    var reg = new RegExp('(\\s|^)' + cls + '(\\s|$)');
    ele.className = ele.className.replace(reg, ' ').replace(/^\s\s*/, '').replace(/\s\s*$/, ''); //last 2 replaces do right trim (see http://blog.stevenlevithan.com/archives/faster-trim-javascript)
  }
};

/*//http://net.tutsplus.com/tutorials/javascript-ajax/javascript-from-null-cross-browser-event-binding/
 WalkontableDom.prototype.addEvent = (function () {
 var that = this;
 if (document.addEventListener) {
 return function (elem, type, cb) {
 if ((elem && !elem.length) || elem === window) {
 elem.addEventListener(type, cb, false);
 }
 else if (elem && elem.length) {
 var len = elem.length;
 for (var i = 0; i < len; i++) {
 that.addEvent(elem[i], type, cb);
 }
 }
 };
 }
 else {
 return function (elem, type, cb) {
 if ((elem && !elem.length) || elem === window) {
 elem.attachEvent('on' + type, function () {

 //normalize
 //http://stackoverflow.com/questions/4643249/cross-browser-event-object-normalization
 var e = window['event'];
 e.target = e.srcElement;
 //e.offsetX = e.layerX;
 //e.offsetY = e.layerY;
 e.relatedTarget = e.relatedTarget || e.type == 'mouseover' ? e.fromElement : e.toElement;
 if (e.target.nodeType === 3) e.target = e.target.parentNode; //Safari bug

 return cb.call(elem, e)
 });
 }
 else if (elem.length) {
 var len = elem.length;
 for (var i = 0; i < len; i++) {
 that.addEvent(elem[i], type, cb);
 }
 }
 };
 }
 })();

 WalkontableDom.prototype.triggerEvent = function (element, eventName, target) {
 var event;
 if (document.createEvent) {
 event = document.createEvent("MouseEvents");
 event.initEvent(eventName, true, true);
 } else {
 event = document.createEventObject();
 event.eventType = eventName;
 }

 event.eventName = eventName;
 event.target = target;

 if (document.createEvent) {
 target.dispatchEvent(event);
 } else {
 target.fireEvent("on" + event.eventType, event);
 }
 };*/

WalkontableDom.prototype.removeTextNodes = function (elem, parent) {
  if (elem.nodeType === 3) {
    parent.removeChild(elem); //bye text nodes!
  }
  else if (['TABLE', 'THEAD', 'TBODY', 'TFOOT', 'TR'].indexOf(elem.nodeName) > -1) {
    var childs = elem.childNodes;
    for (var i = childs.length - 1; i >= 0; i--) {
      this.removeTextNodes(childs[i], elem);
    }
  }
};

/**
 * seems getBounding is usually faster: http://jsperf.com/offset-vs-getboundingclientrect/4
 * but maybe offset + cache would work?
 * edit: after more tests turns out offsetLeft/Top is faster
 */
/*WalkontableDom.prototype.offset = function (elem) {
 var rect = elem.getBoundingClientRect();
 return {
 top: rect.top + document.documentElement.scrollTop,
 left: rect.left + document.documentElement.scrollLeft
 };
 };*/

/*
 WalkontableDom.prototype.offsetLeft = function (elem) {
 var offset = elem.offsetLeft;
 while (elem = elem.offsetParent) {
 offset += elem.offsetLeft;
 }
 return offset;
 };

 WalkontableDom.prototype.offsetTop = function (elem) {
 var offset = elem.offsetTop;
 while (elem = elem.offsetParent) {
 offset += elem.offsetTop;
 }
 return offset;
 };*/

WalkontableDom.prototype.offset = function (elem) {
  var offsetLeft = elem.offsetLeft
    , offsetTop = elem.offsetTop;
  while (elem = elem.offsetParent) {
    offsetLeft += elem.offsetLeft;
    offsetTop += elem.offsetTop;
  }
  return {
    left: offsetLeft,
    top: offsetTop
  };
};
function WalkontableEvent(instance) {
  var that = this;

  //reference to instance
  this.instance = instance;

  this.wtDom = new WalkontableDom();

  var dblClickOrigin = [null, null, null, null]
    , dblClickTimeout = null;

  var onMouseDown = function (event) {
    var cell = that.parentCell(event.target);

    if (cell.TD && cell.TD.nodeName === 'TD') {
      if (that.instance.hasSetting('onCellMouseDown')) {
        that.instance.getSetting('onCellMouseDown', event, cell.coords, cell.TD);
      }
    }
    else if (that.wtDom.hasClass(event.target, 'corner')) {
      that.instance.getSetting('onCellCornerMouseDown', event, event.target);
    }

    if (event.button !== 2) { //if not right mouse button
      if (cell.TD && cell.TD.nodeName === 'TD') {
        dblClickOrigin.shift();
        dblClickOrigin.push(cell.TD);
      }
      else if (that.wtDom.hasClass(event.target, 'corner')) {
        dblClickOrigin.shift();
        dblClickOrigin.push(event.target);
      }
    }
  };

  var lastMouseOver;
  var onMouseOver = function (event) {
    if (that.instance.hasSetting('onCellMouseOver')) {
      var TD = that.wtDom.closest(event.target, ['TD', 'TH']);
      if (TD && TD !== lastMouseOver) {
        lastMouseOver = TD;
        if (TD.nodeName === 'TD') {
          that.instance.getSetting('onCellMouseOver', event, that.instance.wtTable.getCoords(TD), TD);
        }
      }
    }
  };

  var onMouseUp = function (event) {
    if (event.button !== 2) { //if not right mouse button
      var cell = that.parentCell(event.target);

      if (cell.TD && cell.TD.nodeName === 'TD') {
        dblClickOrigin.shift();
        dblClickOrigin.push(cell.TD);
      }
      else {
        dblClickOrigin.shift();
        dblClickOrigin.push(event.target);
      }

      if (dblClickOrigin[3] !== null && dblClickOrigin[3] === dblClickOrigin[2]) {
        if (dblClickTimeout && dblClickOrigin[2] === dblClickOrigin[1] && dblClickOrigin[1] === dblClickOrigin[0]) {
          if (cell.TD) {
            that.instance.getSetting('onCellDblClick', event, cell.coords, cell.TD);
          }
          else if (that.wtDom.hasClass(event.target, 'corner')) {
            that.instance.getSetting('onCellCornerDblClick', event, cell.coords, cell.TD);
          }

          clearTimeout(dblClickTimeout);
          dblClickTimeout = null;
        }
        else {
          clearTimeout(dblClickTimeout);
          dblClickTimeout = setTimeout(function () {
            dblClickTimeout = null;
          }, 500);
        }
      }
    }
  };

  $(this.instance.wtTable.parent).on('mousedown', onMouseDown);
  $(this.instance.wtTable.TABLE).on('mouseover', onMouseOver);
  $(this.instance.wtTable.parent).on('mouseup', onMouseUp);
}

WalkontableEvent.prototype.parentCell = function (elem) {
  var cell = {};
  cell.TD = this.wtDom.closest(elem, ['TD', 'TH']);
  if (cell.TD) {
    cell.coords = this.instance.wtTable.getCoords(cell.TD);
  }
  else if (!cell.TD && this.wtDom.hasClass(elem, 'wtBorder') && this.wtDom.hasClass(elem, 'current') && !this.wtDom.hasClass(elem, 'corner')) {
    cell.coords = this.instance.selections.current.selected[0];
    cell.TD = this.instance.wtTable.getCell(cell.coords);
  }
  return cell;
};
//http://stackoverflow.com/questions/3629183/why-doesnt-indexof-work-on-an-array-ie8
if (!Array.prototype.indexOf) {
  Array.prototype.indexOf = function (elt /*, from*/) {
    var len = this.length >>> 0;

    var from = Number(arguments[1]) || 0;
    from = (from < 0)
      ? Math.ceil(from)
      : Math.floor(from);
    if (from < 0)
      from += len;

    for (; from < len; from++) {
      if (from in this &&
        this[from] === elt)
        return from;
    }
    return -1;
  };
}

/**
 * http://notes.jetienne.com/2011/05/18/cancelRequestAnimFrame-for-paul-irish-requestAnimFrame.html
 */
window.requestAnimFrame = (function () {
  return  window.requestAnimationFrame ||
    window.webkitRequestAnimationFrame ||
    window.mozRequestAnimationFrame ||
    window.oRequestAnimationFrame ||
    window.msRequestAnimationFrame ||
    function (/* function */ callback, /* DOMElement */ element) {
      return window.setTimeout(callback, 1000 / 60);
    };
})();

window.cancelRequestAnimFrame = (function () {
  return window.cancelAnimationFrame ||
    window.webkitCancelRequestAnimationFrame ||
    window.mozCancelRequestAnimationFrame ||
    window.oCancelRequestAnimationFrame ||
    window.msCancelRequestAnimationFrame ||
    clearTimeout
})();
function WalkontableScroll(instance) {
  this.instance = instance;
  this.wtScrollbarV = new WalkontableScrollbar(instance, 'vertical');
  this.wtScrollbarH = new WalkontableScrollbar(instance, 'horizontal');
}

WalkontableScroll.prototype.refreshScrollbars = function () {
  this.wtScrollbarH.prepare();
  this.wtScrollbarV.prepare();
  this.instance.wtTable.recalcViewportCells();
  this.wtScrollbarH.refresh();
  this.wtScrollbarV.refresh();
};

WalkontableScroll.prototype.scrollVertical = function (delta) {
  if (!this.instance.drawn) {
    throw new Error('scrollVertical can only be called after table was drawn to DOM');
  }

  var offsetRow = this.instance.getSetting('offsetRow')
    , newOffsetRow = offsetRow + delta;

  if (newOffsetRow > 0) {
    var totalRows = this.instance.getSetting('totalRows');
    var height = (this.instance.getSetting('height') || Infinity) - this.instance.getSetting('scrollbarHeight'); //Infinity is needed, otherwise you could scroll a table that did not have height specified

    if (newOffsetRow >= totalRows) {
      newOffsetRow = totalRows - 1;
    }

    var TD = this.instance.wtTable.TBODY.firstChild.firstChild;
    if (TD.nodeName === 'TH') {
      TD = TD.nextSibling;
    }
    var cellOffset = this.instance.wtDom.offset(TD);
    var tableOffset = this.instance.wtTable.tableOffset;

    var sum = cellOffset.top - tableOffset.top;
    var row = newOffsetRow;
    while (sum < height && row < totalRows) {
      sum += this.instance.getSetting('rowHeight', row);
      row++;
    }

    if (sum < height) {
      while (newOffsetRow > 0) {
        //if sum still less than available height, we cannot scroll that far (must move offset up)
        sum += this.instance.getSetting('rowHeight', newOffsetRow - 1);
        if (sum < height) {
          newOffsetRow--;
        }
        else {
          break;
        }
      }
    }
  }
  else if (newOffsetRow < 0) {
    newOffsetRow = 0;
  }

  if (newOffsetRow !== offsetRow) {
    this.instance.update('offsetRow', newOffsetRow);
  }
  return this.instance;
};

WalkontableScroll.prototype.scrollHorizontal = function (delta) {
  if (!this.instance.drawn) {
    throw new Error('scrollHorizontal can only be called after table was drawn to DOM');
  }

  var offsetColumn = this.instance.getSetting('offsetColumn')
    , newOffsetColumn = offsetColumn + delta;

  if (newOffsetColumn > 0) {
    var totalColumns = this.instance.getSetting('totalColumns');
    var width = this.instance.getSetting('width');

    if (newOffsetColumn >= totalColumns) {
      newOffsetColumn = totalColumns - 1;
    }

    var TD = this.instance.wtTable.TBODY.firstChild.firstChild;
    if (TD.nodeName === 'TH') {
      TD = TD.nextSibling;
    }
    var cellOffset = this.instance.wtDom.offset(TD);
    var tableOffset = this.instance.wtTable.tableOffset;

    var sum = cellOffset.left - tableOffset.left;
    var col = newOffsetColumn;
    while (sum < width && col < totalColumns) {
      sum += this.instance.getSetting('columnWidth', col);
      col++;
    }

    if (sum < width) {
      while (newOffsetColumn > 0) {
        //if sum still less than available width, we cannot scroll that far (must move offset to the left)
        sum += this.instance.getSetting('columnWidth', newOffsetColumn - 1);
        if (sum < width) {
          newOffsetColumn--;
        }
        else {
          break;
        }
      }
    }
  }
  else if (newOffsetColumn < 0) {
    newOffsetColumn = 0;
  }

  if (newOffsetColumn !== offsetColumn) {
    this.instance.update('offsetColumn', newOffsetColumn);
  }
  return this.instance;
};

/**
 * Scrolls viewport to a cell by minimum number of cells
 */
WalkontableScroll.prototype.scrollViewport = function (coords) {
  var offsetRow = this.instance.getSetting('offsetRow')
    , offsetColumn = this.instance.getSetting('offsetColumn')
    , viewportRows = this.instance.getSetting('viewportRows')
    , viewportColumns = this.instance.getSetting('viewportColumns')
    , totalRows = this.instance.getSetting('totalRows')
    , totalColumns = this.instance.getSetting('totalColumns');

  if (coords[0] < 0 || coords[0] > totalRows - 1) {
    throw new Error('row ' + coords[0] + ' does not exist');
  }
  else if (coords[1] < 0 || coords[1] > totalColumns - 1) {
    throw new Error('column ' + coords[1] + ' does not exist');
  }

  viewportRows = viewportRows || 1; //for cells larger than viewport it reports 0, but we still have to treat it like visible cell
  viewportColumns = viewportColumns || 1;

  if (viewportRows < totalRows) {
    if (coords[0] > offsetRow + viewportRows - 1) {
      this.scrollVertical(coords[0] - (offsetRow + viewportRows - 1));
    }
    else if (coords[0] < offsetRow) {
      this.scrollVertical(coords[0] - offsetRow);
    }
    else {
      this.scrollVertical(0); //Craig's issue: remove row from the last scroll page should scroll viewport a row up if needed
    }
  }
  else {
    //this.scrollVertical(coords[0] - offsetRow); //this should not be needed anymore
  }

  if (viewportColumns > 0 && viewportColumns < totalColumns) {
    if (coords[1] > offsetColumn + viewportColumns - 1) {
      this.scrollHorizontal(coords[1] - (offsetColumn + viewportColumns - 1));
    }
    else if (coords[1] < offsetColumn) {
      this.scrollHorizontal(coords[1] - offsetColumn);
    }
    else {
      this.scrollHorizontal(0); //Craig's issue
    }
  }
  else {
    //this.scrollHorizontal(coords[1] - offsetColumn); //this should not be needed anymore
  }

  return this.instance;
};
function WalkontableScrollbar(instance, type) {
  var that = this;

  //reference to instance
  this.instance = instance;
  this.type = type;
  this.$table = $(this.instance.wtTable.TABLE);

  //create elements
  this.slider = document.createElement('DIV');
  this.slider.style.position = 'absolute';
  this.slider.style.top = '0';
  this.slider.style.left = '0';
  this.slider.style.display = 'none';
  this.slider.className = 'dragdealer ' + type;

  this.handle = document.createElement('DIV');
  this.handle.className = 'handle';

  this.slider.appendChild(this.handle);
  this.instance.wtTable.parent.appendChild(this.slider);

  var firstRun = true;
  this.dragTimeout = null;
  var dragDelta;
  var dragRender = function () {
    that.onScroll(dragDelta);
  };

  this.dragdealer = new Dragdealer(this.slider, {
    vertical: (type === 'vertical'),
    horizontal: (type === 'horizontal'),
    speed: 100,
    yPrecision: 100,
    animationCallback: function (x, y) {
      if (firstRun) {
        firstRun = false;
        return;
      }
      that.skipRefresh = true;
      dragDelta = type === 'vertical' ? y : x;
      if (that.dragTimeout === null) {
        that.dragTimeout = setInterval(dragRender, 100);
        dragRender();
      }
    },
    callback: function (x, y) {
      that.skipRefresh = false;
      clearInterval(that.dragTimeout);
      that.dragTimeout = null;
      dragDelta = type === 'vertical' ? y : x;
      that.onScroll(dragDelta);
    }
  });
  that.skipRefresh = false;
}

WalkontableScrollbar.prototype.onScroll = function (delta) {
  if (this.instance.drawn) {
    var keys = this.type === 'vertical' ? ['offsetRow', 'totalRows', 'viewportRows', 'top', 'height'] : ['offsetColumn', 'totalColumns', 'viewportColumns', 'left', 'width'];
    var total = this.instance.getSetting(keys[1]);
    var display = this.instance.getSetting(keys[2]);
    if (total > display) {
      var newOffset = Math.round(parseInt(this.handle.style[keys[3]]) * total / parseInt(this.slider.style[keys[4]])); //offset = handlePos * totalRows / offsetRows

      if (delta === 1) {
        if (this.type === 'vertical') {
          this.instance.scrollVertical(Infinity).draw();
        }
        else {
          this.instance.scrollHorizontal(Infinity).draw();
        }
      }
      else if (newOffset !== this.instance.getSetting(keys[0])) { //is new offset different than old offset
        if (this.type === 'vertical') {
          this.instance.scrollVertical(newOffset - this.instance.getSetting(keys[0])).draw();
        }
        else {
          this.instance.scrollHorizontal(newOffset - this.instance.getSetting(keys[0])).draw();
        }
      }
      else {
        this.refresh();
      }
    }
  }
};

/**
 * Returns what part of the scroller should the handle take
 * @param viewportCount {Number} number of visible rows or columns
 * @param totalCount {Number} total number of rows or columns
 * @return {Number} 0..1
 */
WalkontableScrollbar.prototype.getHandleSizeRatio = function (viewportCount, totalCount) {
  if (!totalCount) {
    return 1;
  }
  if (viewportCount > totalCount) { //it exists in code since long time, but does it even happen
    viewportCount = totalCount;
  }
  return viewportCount / totalCount;
};

WalkontableScrollbar.prototype.prepare = function () {
  if (this.skipRefresh) {
    return;
  }
  var ratio
    , scroll;

  if (this.type === 'vertical') {
    ratio = this.getHandleSizeRatio(this.instance.getSetting('viewportRows'), this.instance.getSetting('totalRows'));
    scroll = this.instance.getSetting('scrollV');

  }
  else {
    ratio = this.getHandleSizeRatio(this.instance.getSetting('viewportColumns'), this.instance.getSetting('totalColumns'));
    scroll = this.instance.getSetting('scrollH');
  }

  if (((ratio === 1 || isNaN(ratio)) && scroll === 'auto') || scroll === 'none') {
    //isNaN is needed because ratio equals NaN when totalRows/totalColumns equals 0
    this.visible = false;
  }
  else {
    this.visible = true;
  }
};

WalkontableScrollbar.prototype.refresh = function () {
  if (this.skipRefresh) {
    return;
  }
  else if (!this.visible) {
    this.slider.style.display = 'none';
    return;
  }

  var ratio
    , sliderSize
    , handleSize
    , handlePosition
    , offsetCount
    , totalCount
    , tableOuterWidth = this.$table.outerWidth()
    , tableOuterHeight = this.$table.outerHeight()
    , tableWidth = this.instance.hasSetting('width') ? this.instance.getSetting('width') : tableOuterWidth
    , tableHeight = this.instance.hasSetting('height') ? this.instance.getSetting('height') : tableOuterHeight;

  if (!tableWidth) {
    //throw new Error("I could not compute table width. Is the <table> element attached to the DOM?");
    return;
  }
  if (!tableHeight) {
    //throw new Error("I could not compute table height. Is the <table> element attached to the DOM?");
    return;
  }

  if (this.instance.hasSetting('width') && this.instance.wtScroll.wtScrollbarV.visible) {
    tableWidth -= this.instance.getSetting('scrollbarWidth');
  }
  if (tableWidth > tableOuterWidth + this.instance.getSetting('scrollbarWidth')) {
    tableWidth = tableOuterWidth;
  }

  if (this.instance.hasSetting('height') && this.instance.wtScroll.wtScrollbarH.visible) {
    tableHeight -= this.instance.getSetting('scrollbarHeight');
  }
  if (tableHeight > tableOuterHeight + this.instance.getSetting('scrollbarHeight')) {
    tableHeight = tableOuterHeight;
  }

  if (this.type === 'vertical') {
    offsetCount = this.instance.getSetting('offsetRow');
    totalCount = this.instance.getSetting('totalRows');
    ratio = this.getHandleSizeRatio(this.instance.getSetting('viewportRows'), totalCount);

    sliderSize = tableHeight - 2; //2 is sliders border-width

    this.slider.style.top = this.$table.position().top + 'px';
    this.slider.style.left = tableWidth - 1 + 'px'; //1 is sliders border-width
    this.slider.style.height = sliderSize + 'px';
  }
  else { //horizontal
    offsetCount = this.instance.getSetting('offsetColumn');
    totalCount = this.instance.getSetting('totalColumns');
    ratio = this.getHandleSizeRatio(this.instance.getSetting('viewportColumns'), totalCount);

    sliderSize = tableWidth - 2; //2 is sliders border-width

    this.slider.style.left = this.$table.position().left + 'px';
    this.slider.style.top = tableHeight - 1 + 'px'; //1 is sliders border-width
    this.slider.style.width = sliderSize + 'px';
  }

  handleSize = Math.round(sliderSize * ratio);
  if (handleSize < 10) {
    handleSize = 15;
  }
  handlePosition = Math.round(sliderSize * (offsetCount / totalCount));
  if (handlePosition > tableWidth - handleSize) {
    handlePosition = tableWidth - handleSize;
  }

  if (this.type === 'vertical') {
    this.handle.style.height = handleSize + 'px';
    this.handle.style.top = handlePosition + 'px';
  }
  else { //horizontal
    this.handle.style.width = handleSize + 'px';
    this.handle.style.left = handlePosition + 'px';
  }

  this.slider.style.display = 'block';

  this.dragdealer.setWrapperOffset();
  this.dragdealer.setBounds();
};
function WalkontableSelection(instance, settings) {
  this.instance = instance;
  this.settings = settings;
  this.selected = [];
  if (settings.border) {
    this.border = new WalkontableBorder(instance, settings);
  }
  this.onAdd = function (coords) {
    var TD = instance.wtTable.getCell(coords);
    if (typeof TD === 'object') {
      if (settings.className) {
        instance.wtDom.addClass(TD, settings.className);
      }
    }
  };
  /*this.onRemove = function (coords) {
   var TD = instance.wtTable.getCell(coords);
   if (typeof TD === 'object') {
   if (settings.className) {
   instance.wtDom.removeClass(TD, settings.className);
   }
   }
   };*/
}

WalkontableSelection.prototype.add = function (coords) {
  this.selected.push(coords);
};

WalkontableSelection.prototype.remove = function (coords) {
  var index = this.isSelected(coords);
  if (index > -1) {
    this.selected.splice(index, 1);
  }
};

WalkontableSelection.prototype.clear = function () {
  this.selected.length = 0; //http://jsperf.com/clear-arrayxxx
};

WalkontableSelection.prototype.isSelected = function (coords) {
  for (var i = 0, ilen = this.selected.length; i < ilen; i++) {
    if (this.selected[i][0] === coords[0] && this.selected[i][1] === coords[1]) {
      return i;
    }
  }
  return -1;
};

WalkontableSelection.prototype.getSelected = function () {
  return this.selected;
};

/**
 * Returns the top left (TL) and bottom right (BR) selection coordinates
 * @returns {Object}
 */
WalkontableSelection.prototype.getCorners = function () {
  var minRow
    , minColumn
    , maxRow
    , maxColumn
    , i
    , ilen = this.selected.length;

  if (ilen > 0) {
    minRow = maxRow = this.selected[0][0];
    minColumn = maxColumn = this.selected[0][1];

    if (ilen > 1) {
      for (i = 1; i < ilen; i++) {
        if (this.selected[i][0] < minRow) {
          minRow = this.selected[i][0];
        }
        else if (this.selected[i][0] > maxRow) {
          maxRow = this.selected[i][0];
        }

        if (this.selected[i][1] < minColumn) {
          minColumn = this.selected[i][1];
        }
        else if (this.selected[i][1] > maxColumn) {
          maxColumn = this.selected[i][1];
        }
      }
    }
  }

  return [minRow, minColumn, maxRow, maxColumn];
};

WalkontableSelection.prototype.draw = function (selectionsOnly) {
  var TDs, TD, i, ilen, corners, r, c;

  ilen = this.selected.length;
  if (ilen) {
    corners = this.getCorners();
    var offsetRow = this.instance.getSetting('offsetRow')
      , lastVisibleRow = offsetRow + this.instance.getSetting('displayRows') - 1
      , offsetColumn = this.instance.getSetting('offsetColumn')
      , lastVisibleColumn = offsetColumn + this.instance.getSetting('displayColumns') - 1
      , currentRowClassName = this.instance.getSetting('currentRowClassName')
      , currentColumnClassName = this.instance.getSetting('currentColumnClassName');

    for (r = offsetRow; r <= lastVisibleRow; r++) {
      for (c = offsetColumn; c <= lastVisibleColumn; c++) {
        TD = this.instance.wtTable.getCell([r, c]);
        if (r >= corners[0] && r <= corners[2] && c >= corners[1] && c <= corners[3]) {
          //selected cell
          currentRowClassName && this.instance.wtDom.removeClass(TD, currentRowClassName);
          currentColumnClassName && this.instance.wtDom.removeClass(TD, currentColumnClassName);
          this.onAdd([r, c], TD);
        }
        else if (r >= corners[0] && r <= corners[2]) {
          //selection is in this row
          currentColumnClassName && this.instance.wtDom.removeClass(TD, currentColumnClassName);
          currentRowClassName && this.instance.wtDom.addClass(TD, currentRowClassName);
          this.instance.wtDom.removeClass(TD, this.settings.className);
        }
        else if (c >= corners[1] && c <= corners[3]) {
          //selection is in this column
          currentRowClassName && this.instance.wtDom.removeClass(TD, currentRowClassName);
          currentColumnClassName && this.instance.wtDom.addClass(TD, currentColumnClassName);
          this.instance.wtDom.removeClass(TD, this.settings.className);
        }
        else {
          //no selection
          currentRowClassName && this.instance.wtDom.removeClass(TD, currentRowClassName);
          currentColumnClassName && this.instance.wtDom.removeClass(TD, currentColumnClassName);
          this.instance.wtDom.removeClass(TD, this.settings.className);
        }
      }
    }

    this.border && this.border.appear(corners);
  }
  else {
    if (selectionsOnly && this.settings.className) {
      TDs = this.instance.wtTable.TABLE.getElementsByTagName('TD');
      for (i = 0, ilen = TDs.length; i < ilen; i++) {
        this.instance.wtDom.removeClass(TDs[i], this.settings.className);
      }
    }
    this.border && this.border.disappear();
  }
};

/*WalkontableSelection.prototype.rectangleSize = function () {
 var that = this
 , rowLengths = {}
 , rowBegins = {}
 , rowEnds = {}
 , row
 , col
 , rowSpan
 , colSpan
 , lastRow
 , i
 , ilen
 , j
 , height = 0
 , tableSection
 , lastTableSection;

 this.selected.sort(function (a, b) {
 return that.wtCell.colIndex(a) - that.wtCell.colIndex(b);
 });

 this.selected.sort(function (a, b) {
 return that.wtCell.rowIndex(a) - that.wtCell.rowIndex(b);
 });

 for (i = 0, ilen = this.selected.length; i < ilen; i++) {
 tableSection = this.wtDom.closestParent(this.selected[i], ['THEAD', 'TBODY', 'TFOOT', 'TABLE']);
 if(lastTableSection && lastTableSection !== tableSection) {
 return null; //can only select cells that are in the same section (thead, tbody, tfoot or table if none of them is defined)
 }
 lastTableSection = tableSection;

 row = this.wtCell.rowIndex(this.selected[i]);
 col = this.wtCell.colIndex(this.selected[i]);
 rowSpan = this.selected[i].rowSpan;
 colSpan = this.selected[i].colSpan;
 for (j = 0; j < rowSpan; j++) {
 if (typeof rowBegins[row + j] === 'undefined' || col < rowBegins[row + j]) {
 rowBegins[row + j] = col;
 }
 if (typeof rowEnds[row + j] === 'undefined' || col + colSpan - 1 > rowEnds[row + j]) {
 rowEnds[row + j] = col + colSpan - 1;
 }
 if (typeof rowLengths[row + j] === 'undefined') {
 rowLengths[row + j] = 0;
 height++;
 }
 rowLengths[row + j] += colSpan;
 }
 }

 if (!ilen) {
 return null; //empty selection
 }

 lastRow = -1;
 for (i in rowBegins) {
 if (rowBegins.hasOwnProperty(i)) {
 if (lastRow !== -1 && rowBegins[i] !== lastRow) {
 return null; //selected rows begin in different column
 }
 lastRow = rowBegins[i];
 }
 }

 lastRow = -1;
 for (i in rowEnds) {
 if (rowEnds.hasOwnProperty(i)) {
 if (lastRow !== -1 && rowEnds[i] !== lastRow) {
 return null; //selected rows end in different column
 }
 if (rowEnds[i] !== rowBegins[i] + rowLengths[i] - 1) {
 return null; //selected rows end does not match begin + length
 }
 lastRow = rowEnds[i];
 }
 }

 lastRow = -1;
 for (i in rowLengths) {
 if (rowLengths.hasOwnProperty(i)) {
 if (lastRow !== -1 && rowLengths[i] !== lastRow) {
 return null; //selected rows have different length
 }
 if (lastRow !== -1 && !rowLengths.hasOwnProperty(i - 1)) {
 return null; //there is a row gap in selection
 }
 lastRow = rowLengths[i];
 }
 }

 return {width: lastRow, height: height};
 };*/
function WalkontableSettings(instance, settings) {
  var that = this;
  this.instance = instance;

  //default settings. void 0 means it is required, null means it can be empty
  this.defaults = {
    table: void 0,

    //presentation mode
    async: false,
    scrollH: 'auto', //values: scroll (always show scrollbar), auto (show scrollbar if table does not fit in the container), none (never show scrollbar)
    scrollV: 'auto', //values: see above
    stretchH: 'hybrid', //values: hybrid, all, last, none
    currentRowClassName: null,
    currentColumnClassName: null,

    //data source
    data: void 0,
    offsetRow: 0,
    offsetColumn: 0,
    frozenColumns: null,
    columnHeaders: null, //this must be a function in format: function (col, TH) {}
    totalRows: void 0,
    totalColumns: void 0,
    width: null,
    height: null,
    cellRenderer: function (row, column, TD) {
      var cellData = that.getSetting('data', row, column);
      if (cellData !== void 0) {
        TD.innerHTML = cellData;
      }
      else {
        TD.innerHTML = '';
      }
    },
    columnWidth: 50,
    selections: null,

    //callbacks
    onCellMouseDown: null,
    onCellMouseOver: null,
    onCellDblClick: null,
    onCellCornerMouseDown: null,
    onCellCornerDblClick: null,

    //constants
    scrollbarWidth: 10,
    scrollbarHeight: 10
  };

  //reference to settings
  this.settings = {};
  for (var i in this.defaults) {
    if (this.defaults.hasOwnProperty(i)) {
      if (settings[i] !== void 0) {
        this.settings[i] = settings[i];
      }
      else if (this.defaults[i] === void 0) {
        throw new Error('A required setting "' + i + '" was not provided');
      }
      else {
        this.settings[i] = this.defaults[i];
      }
    }
  }

  this.rowHeightCache = [];
}

/**
 * generic methods
 */

WalkontableSettings.prototype.update = function (settings, value) {
  if (value === void 0) { //settings is object
    for (var i in settings) {
      if (settings.hasOwnProperty(i)) {
        this.settings[i] = settings[i];
      }
    }
  }
  else { //if value is defined then settings is the key
    this.settings[settings] = value;
  }
  return this.instance;
};

WalkontableSettings.prototype.getSetting = function (key, param1, param2, param3) {
  if (this[key]) {
    return this[key](param1, param2, param3);
  }
  else {
    return this._getSetting(key, param1, param2, param3);
  }
};

WalkontableSettings.prototype._getSetting = function (key, param1, param2, param3) {
  if (typeof this.settings[key] === 'function') {
    return this.settings[key](param1, param2, param3);
  }
  else if (param1 !== void 0 && Object.prototype.toString.call(this.settings[key]) === '[object Array]' && param1 !== void 0) {
    return this.settings[key][param1];
  }
  else {
    return this.settings[key];
  }
};

WalkontableSettings.prototype.has = function (key) {
  return !!this.settings[key]
};

/**
 * specific methods
 */

WalkontableSettings.prototype.rowHeight = function (row) {
  if (typeof this.rowHeightCache[row] !== 'undefined') {
    return this.rowHeightCache[row];
  }
  return 20;
};

WalkontableSettings.prototype.columnWidth = function (column) {
  return Math.min(200, this._getSetting('columnWidth', column));
};

WalkontableSettings.prototype.displayRows = function () {
  var estimated
    , calculated;

  if (this.settings['height']) {
    estimated = Math.ceil(this.settings['height'] / 20); //silly assumption but should be fine for now
    calculated = this.getSetting('totalRows') - this.getSetting('offsetRow');
    if (calculated < 0) {
      this.update('offsetRow', Math.max(0, this.getSetting('totalRows') - estimated));
      return estimated;
    }
    else {
      return Math.min(estimated, calculated);
    }
  }
  else {
    return this.getSetting('totalRows');
  }
};

WalkontableSettings.prototype.displayColumns = function () {
  var estimated
    , calculated;

  if (this.settings['width']) {
    estimated = Math.ceil(this.settings['width'] / 50); //silly assumption but should be fine for now
    calculated = this.getSetting('totalColumns') - this.getSetting('offsetColumn');
    if (calculated < 0) {
      this.update('offsetColumn', Math.max(0, this.getSetting('totalColumns') - estimated));
      return estimated;
    }
    else {
      return Math.min(estimated, calculated);
    }
  }
  else {
    return this.getSetting('totalColumns');
  }
};

WalkontableSettings.prototype.viewportRows = function () {
  if (this.instance.wtTable.visibilityEdgeRow !== null) {
    return this.instance.wtTable.visibilityEdgeRow - this.instance.wtTable.visibilityStartRow;
  }
  return this.getSetting('displayRows');
};

WalkontableSettings.prototype.viewportColumns = function () {
  if (this.instance.wtTable.visibilityEdgeColumn !== null) {
    return this.instance.wtTable.visibilityEdgeColumn - this.instance.wtTable.visibilityStartColumn;
  }
  return this.getSetting('displayColumns');
};
function WalkontableTable(instance) {
  //reference to instance
  this.instance = instance;
  this.TABLE = this.instance.getSetting('table');
  this.wtDom = new WalkontableDom();
  this.wtDom.removeTextNodes(this.TABLE);

  this.hasEmptyCellProblem = ($.browser.msie && (parseInt($.browser.version, 10) <= 7));
  this.hasCellSpacingProblem = ($.browser.msie && (parseInt($.browser.version, 10) <= 7));

  if (this.hasCellSpacingProblem) { //IE7
    this.TABLE.cellSpacing = 0;
  }

  this.visibilityStartRow = this.visibilityStartColumn = this.visibilityEdgeRow = this.visibilityEdgeColumn = null;

  //wtSpreader
  var parent = this.TABLE.parentNode;
  if (!parent || parent.nodeType !== 1 || !this.wtDom.hasClass(parent, 'wtHolder')) {
    var spreader = document.createElement('DIV');
    if (this.instance.hasSetting('width') && this.instance.hasSetting('height')) {
      spreader.style.position = 'absolute';
      spreader.style.top = '0';
      spreader.style.left = '0';
      spreader.style.width = '4000px';
      spreader.style.height = '4000px';
    }
    spreader.className = 'wtSpreader';
    if (parent) {
      parent.insertBefore(spreader, this.TABLE); //if TABLE is detached (e.g. in Jasmine test), it has no parentNode so we cannot attach holder to it
    }
    spreader.appendChild(this.TABLE);
  }
  this.spreader = this.TABLE.parentNode;

  //wtHider
  parent = this.spreader.parentNode;
  if (!parent || parent.nodeType !== 1 || !this.wtDom.hasClass(parent, 'wtHolder')) {
    var hider = document.createElement('DIV');
    hider.style.position = 'relative';
    hider.className = 'wtHider';
    if (parent) {
      parent.insertBefore(hider, this.spreader); //if TABLE is detached (e.g. in Jasmine test), it has no parentNode so we cannot attach holder to it
    }
    hider.appendChild(this.spreader);
  }
  this.hider = this.spreader.parentNode;

  //wtHolder
  parent = this.hider.parentNode;
  if (!parent || parent.nodeType !== 1 || !this.wtDom.hasClass(parent, 'wtHolder')) {
    var holder = document.createElement('DIV');
    holder.style.position = 'relative';
    holder.className = 'wtHolder';
    if (parent) {
      parent.insertBefore(holder, this.hider); //if TABLE is detached (e.g. in Jasmine test), it has no parentNode so we cannot attach holder to it
    }
    holder.appendChild(this.hider);
  }
  this.parent = this.hider.parentNode;

  //bootstrap from settings
  this.TBODY = this.TABLE.getElementsByTagName('TBODY')[0];
  if (!this.TBODY) {
    this.TBODY = document.createElement('TBODY');
    this.TABLE.appendChild(this.TBODY);
  }
  this.THEAD = this.TABLE.getElementsByTagName('THEAD')[0];
  if (!this.THEAD) {
    this.THEAD = document.createElement('THEAD');
    this.TABLE.insertBefore(this.THEAD, this.TBODY);
  }
  this.COLGROUP = this.TABLE.getElementsByTagName('COLGROUP')[0];
  if (!this.COLGROUP) {
    this.COLGROUP = document.createElement('COLGROUP');
    this.TABLE.insertBefore(this.COLGROUP, this.THEAD);
  }

  if (this.instance.hasSetting('columnHeaders')) {
    if (!this.THEAD.childNodes.length) {
      var TR = document.createElement('TR');
      this.THEAD.appendChild(TR);
    }
  }

  this.colgroupChildrenLength = this.COLGROUP.childNodes.length;
  this.theadChildrenLength = this.THEAD.firstChild ? this.THEAD.firstChild.childNodes.length : 0;
  this.tbodyChildrenLength = this.TBODY.childNodes.length;
}

WalkontableTable.prototype.refreshHiderDimensions = function () {
  var height = this.instance.getSetting('height');
  var width = this.instance.getSetting('width');

  if (height || width) {
    this.hider.style.overflow = 'hidden';
  }

  if (height) {
    if (this.instance.wtScroll.wtScrollbarH.visible) {
      this.hider.style.height = height - this.instance.getSetting('scrollbarHeight') + 'px';
    }
    else {
      this.hider.style.height = height + 'px';
    }
  }
  if (width) {
    if (this.instance.wtScroll.wtScrollbarV.visible) {
      this.hider.style.width = width - this.instance.getSetting('scrollbarWidth') + 'px';
    }
    else {
      this.hider.style.width = width + 'px';
    }
  }
};

WalkontableTable.prototype.refreshStretching = function () {
  var stretchH = this.instance.getSetting('stretchH')
    , totalColumns = this.instance.getSetting('totalColumns')
    , displayColumns = this.instance.getSetting('displayColumns')
    , displayTds = Math.min(displayColumns, totalColumns)
    , offsetColumn = this.instance.getSetting('offsetColumn')
    , frozenColumns = this.instance.getSetting('frozenColumns')
    , frozenColumnsCount = frozenColumns ? frozenColumns.length : 0;

  if (!this.instance.hasSetting('columnWidth')) {
    return;
  }

  if (stretchH === 'hybrid') {
    if (this.instance.wtScroll.wtScrollbarH.visible) {
      stretchH = 'last';
    }
    else {
      stretchH = 'none';
    }
  }

  var TD;
  if (this.instance.wtTable.TBODY.firstChild && this.instance.wtTable.TBODY.firstChild.firstChild) {
    TD = this.instance.wtTable.TBODY.firstChild.firstChild;
  }
  else if (this.instance.wtTable.THEAD.firstChild && this.instance.wtTable.THEAD.firstChild.firstChild) {
    TD = this.instance.wtTable.THEAD.firstChild.firstChild;
  }

  if (frozenColumnsCount) {
    TD = TD.nextSibling;
  }

  if (!TD) {
    return;
  }

  var cellOffset = this.instance.wtDom.offset(TD)
    , tableOffset = this.instance.wtTable.tableOffset
    , rowHeaderWidth = cellOffset.left - tableOffset.left
    , widths = []
    , widthSum = 0
    , c;
  for (c = 0; c < displayTds; c++) {
    widths.push(this.instance.getSetting('columnWidth', offsetColumn + c));
    widthSum += widths[c];
  }
  var domWidth = widthSum + rowHeaderWidth;

  if (stretchH === 'all' || stretchH === 'last') {
    var containerWidth = this.instance.getSetting('width');
    if (this.instance.wtScroll.wtScrollbarV.visible) {
      containerWidth -= this.instance.getSetting('scrollbarWidth');
    }

    var diff = containerWidth - domWidth;
    if (diff > 0) {
      if (stretchH === 'all') {
        var newWidth;
        var remainingDiff = diff;
        var ratio = diff / widthSum;

        for (c = 0; c < displayTds; c++) {
          if (widths[c]) {
            if (c === displayTds - 1) {
              newWidth = widths[c] + remainingDiff;
            }
            else {
              newWidth = widths[c] + Math.floor(ratio * widths[c]);
              remainingDiff -= Math.floor(ratio * widths[c]);
            }
          }
          widths[c] = newWidth;
        }
      }
      else {
        if (widths[widths.length - 1]) {
          widths[widths.length - 1] = widths[widths.length - 1] + diff;
        }
      }
    }
  }

  for (c = 0; c < displayTds; c++) {
    if (widths[c]) {
      this.COLGROUP.childNodes[c + frozenColumnsCount].style.width = widths[c] + 'px';
    }
    else {
      this.COLGROUP.childNodes[c + frozenColumnsCount].style.width = '';
    }
  }
};

WalkontableTable.prototype.adjustAvailableNodes = function () {
  var totalRows = this.instance.getSetting('totalRows')
    , totalColumns = this.instance.getSetting('totalColumns')
    , displayRows = this.instance.getSetting('displayRows')
    , displayColumns = this.instance.getSetting('displayColumns')
    , displayTds
    , frozenColumns = this.instance.getSetting('frozenColumns')
    , frozenColumnsCount = frozenColumns ? frozenColumns.length : 0
    , TR
    , c;

  displayRows = Math.min(displayRows, totalRows);
  displayTds = Math.min(displayColumns, totalColumns);

  //adjust COLGROUP
  while (this.colgroupChildrenLength < displayTds + frozenColumnsCount) {
    this.COLGROUP.appendChild(document.createElement('COL'));
    this.colgroupChildrenLength++;
  }
  while (this.colgroupChildrenLength > displayTds + frozenColumnsCount) {
    this.COLGROUP.removeChild(this.COLGROUP.lastChild);
    this.colgroupChildrenLength--;
  }

  //adjust THEAD
  if (this.instance.hasSetting('columnHeaders')) {
    while (this.theadChildrenLength < displayTds + frozenColumnsCount) {
      this.THEAD.firstChild.appendChild(document.createElement('TH'));
      this.theadChildrenLength++;
    }
    while (this.theadChildrenLength > displayTds + frozenColumnsCount) {
      this.THEAD.firstChild.removeChild(this.THEAD.firstChild.lastChild);
      this.theadChildrenLength--;
    }
  }

  //adjust TBODY
  while (this.tbodyChildrenLength < displayRows) {
    TR = document.createElement('TR');
    for (c = 0; c < frozenColumnsCount; c++) {
      TR.appendChild(document.createElement('TH'));
    }
    for (c = 0; c < displayTds; c++) {
      TR.appendChild(document.createElement('TD'));
    }
    this.TBODY.appendChild(TR);
    this.tbodyChildrenLength++;
  }
  while (this.tbodyChildrenLength > displayRows) {
    this.TBODY.removeChild(this.TBODY.lastChild);
    this.tbodyChildrenLength--;
  }

  var TRs = this.TBODY.childNodes;
  var trChildrenLength;
  for (var r = 0, rlen = TRs.length; r < rlen; r++) {
    trChildrenLength = TRs[r].childNodes.length;
    while (trChildrenLength < displayTds + frozenColumnsCount) {
      TRs[r].appendChild(document.createElement('TD'));
      trChildrenLength++;
    }
    while (trChildrenLength > displayTds + frozenColumnsCount) {
      TRs[r].removeChild(TRs[r].lastChild);
      trChildrenLength--;
    }
  }
};

WalkontableTable.prototype.draw = function (selectionsOnly) {
  if (!selectionsOnly) {
    this.tableOffset = this.wtDom.offset(this.TABLE);
    //this.TABLE.removeChild(this.TBODY); //possible future optimization - http://jsperf.com/table-scrolling/9
    this.adjustAvailableNodes();
    this._doDraw();
    //this.TABLE.appendChild(this.TBODY);
  }

  //redraw selections and scrollbars
  if (this.instance.hasSetting('async')) {
    var that = this;
    window.cancelRequestAnimFrame(this.selectionsFrame);
    that.selectionsFrame = window.requestAnimFrame(function () {
      that.refreshPositions(selectionsOnly);
    });
  }
  else {
    this.refreshPositions(selectionsOnly);
  }

  this.instance.drawn = true;
  return this;
};

WalkontableTable.prototype._doDraw = function () {
  var r
    , c
    , offsetRow = this.instance.getSetting('offsetRow')
    , offsetColumn = this.instance.getSetting('offsetColumn')
    , totalRows = this.instance.getSetting('totalRows')
    , totalColumns = this.instance.getSetting('totalColumns')
    , displayRows = this.instance.getSetting('displayRows')
    , displayColumns = this.instance.getSetting('displayColumns')
    , displayTds
    , frozenColumns = this.instance.getSetting('frozenColumns')
    , frozenColumnsCount = frozenColumns ? frozenColumns.length : 0
    , TR
    , TH
    , TD
    , cellData;

  displayRows = Math.min(displayRows, totalRows);
  displayTds = Math.min(displayColumns, totalColumns);

  //draw COLGROUP
  for (c = 0; c < this.colgroupChildrenLength; c++) {
    if (c < frozenColumnsCount) {
      this.wtDom.addClass(this.COLGROUP.childNodes[c], 'rowHeader');
      if (typeof frozenColumns[c] === "function") {
        frozenColumns[c](null, this.COLGROUP.childNodes[c])
      }
    }
    else {
      this.wtDom.removeClass(this.COLGROUP.childNodes[c], 'rowHeader');
    }
  }

  this.refreshStretching(); //needed here or otherwise scrollbarH is not shown

  //draw THEAD
  if (frozenColumnsCount && this.instance.hasSetting('columnHeaders')) {
    for (c = 0; c < frozenColumnsCount; c++) {
      TH = this.THEAD.childNodes[0].childNodes[c];
      if (typeof frozenColumns[c] === "function") {
        frozenColumns[c](null, TH);
      }
      else {
        TH.innerHTML = '';
      }
      if (this.hasEmptyCellProblem && TH.innerHTML === '') { //IE7
        TH.innerHTML = '&nbsp;';
      }
    }
  }

  if (this.instance.hasSetting('columnHeaders')) {
    for (c = 0; c < displayTds; c++) {
      this.instance.getSetting('columnHeaders', offsetColumn + c, this.THEAD.childNodes[0].childNodes[frozenColumnsCount + c]);
    }
  }

  //draw TBODY
  this.visibilityEdgeRow = this.visibilityEdgeColumn = null;
  this.visibilityStartRow = offsetRow; //needed bacause otherwise the values get out of sync in async mode
  this.visibilityStartColumn = offsetColumn;
  for (r = 0; r < displayRows; r++) {
    TR = this.TBODY.childNodes[r];
    for (c = 0; c < frozenColumnsCount; c++) { //in future use nextSibling; http://jsperf.com/nextsibling-vs-indexed-childnodes
      TH = TR.childNodes[c];
      cellData = typeof frozenColumns[c] === "function" ? frozenColumns[c](offsetRow + r, TH) : frozenColumns[c];
      if (cellData !== void 0) {
        TH.innerHTML = cellData;
      }
      /*
       we can assume that frozenColumns[c] function took care of inserting content into TH
       else {
       TH.innerHTML = '';
       }*/
    }

    var visibilityFullRow = null;
    var visibilityFullColumn = null;

    for (c = 0; c < displayTds; c++) { //in future use nextSibling; http://jsperf.com/nextsibling-vs-indexed-childnodes
      if (this.visibilityEdgeColumn !== null && offsetColumn + c > this.visibilityEdgeColumn) {
        break;
      }
      else {
        TD = TR.childNodes[c + frozenColumnsCount];
        TD.className = '';
        this.instance.getSetting('cellRenderer', offsetRow + r, offsetColumn + c, TD);
        if (this.hasEmptyCellProblem && TD.innerHTML === '') { //IE7
          TD.innerHTML = '&nbsp;';
        }

        var visibility = this.isCellVisible(offsetRow + r, offsetColumn + c, TD);
        if (this.visibilityEdgeColumn === null && visibility & FLAG_VISIBLE_HORIZONTAL) {
          visibilityFullColumn = offsetColumn + c;
        }
        else if (this.visibilityEdgeColumn === null && visibility & FLAG_PARTIALLY_VISIBLE_HORIZONTAL) {
          this.visibilityEdgeColumn = offsetColumn + c;
        }

        if (this.visibilityEdgeRow === null && visibility & FLAG_VISIBLE_VERTICAL) {
          visibilityFullRow = offsetRow + r;
        }
        else if (this.visibilityEdgeRow === null && visibility & FLAG_PARTIALLY_VISIBLE_VERTICAL) {
          this.visibilityEdgeRow = offsetRow + r;
        }
      }
    }
    /*if (this.visibilityEdgeRow !== null && offsetRow + r > this.visibilityEdgeRow) {
     break;
     }*/
  }

  if (this.visibilityEdgeRow === null) {
    this.visibilityEdgeRow = visibilityFullRow + 1;
  }
  if (this.visibilityEdgeColumn === null) {
    this.visibilityEdgeColumn = visibilityFullColumn + 1;
  }
};

WalkontableTable.prototype.refreshPositions = function (selectionsOnly) {
  this.instance.wtScroll.refreshScrollbars();
  this.refreshHiderDimensions();
  this.refreshStretching();
  this.refreshSelections(selectionsOnly);
};

WalkontableTable.prototype.refreshSelections = function (selectionsOnly) {
  var r;
  if (this.instance.selections) {
    for (r in this.instance.selections) {
      if (this.instance.selections.hasOwnProperty(r)) {
        this.instance.selections[r].draw(selectionsOnly);
      }
    }
  }
};

WalkontableTable.prototype.recalcViewportCells = function () {
  if (this.instance.wtScroll.wtScrollbarV.visible && this.visibilityEdgeColumnRemainder <= this.instance.getSetting('scrollbarWidth')) {
    this.visibilityEdgeColumn--;
    this.visibilityEdgeColumnRemainder = Infinity;
  }
  if (this.instance.wtScroll.wtScrollbarH.visible && this.visibilityEdgeRowRemainder <= this.instance.getSetting('scrollbarHeight')) {
    this.visibilityEdgeRow--;
    this.visibilityEdgeRowRemainder = Infinity;
  }
};

var FLAG_VISIBLE_HORIZONTAL = 0x1; // 000001
var FLAG_VISIBLE_VERTICAL = 0x2; // 000010
var FLAG_PARTIALLY_VISIBLE_HORIZONTAL = 0x4; // 000100
var FLAG_PARTIALLY_VISIBLE_VERTICAL = 0x8; // 001000
var FLAG_NOT_VISIBLE_HORIZONTAL = 0x16; // 010000
var FLAG_NOT_VISIBLE_VERTICAL = 0x32; // 100000

WalkontableTable.prototype.isCellVisible = function (r, c, TD) {
  var out = 0
    , scrollV = this.instance.getSetting('scrollV')
    , scrollH = this.instance.getSetting('scrollH')
    , cellOffset = this.wtDom.offset(TD)
    , tableOffset = this.tableOffset
    , innerOffsetTop = cellOffset.top - tableOffset.top
    , innerOffsetLeft = cellOffset.left - tableOffset.left
    , $td = $(TD)
    , width = $td.outerWidth()
    , height = $td.outerHeight()
    , tableWidth = this.instance.hasSetting('width') ? this.instance.getSetting('width') : Infinity
    , tableHeight = this.instance.hasSetting('height') ? this.instance.getSetting('height') : Infinity;

  this.instance.wtSettings.rowHeightCache[r] = height;

  /**
   * Legend:
   * 0 - not visible vertically
   * 1 - not visible horizontally
   * 2 - partially visible vertically
   * 3 - partially visible horizontally
   * 4 - visible
   */

  if (innerOffsetTop > tableHeight) {
    out |= FLAG_NOT_VISIBLE_VERTICAL;
  }
  else if (innerOffsetTop + height > tableHeight) {
    this.visibilityEdgeRowRemainder = tableHeight - innerOffsetTop;
    out |= FLAG_PARTIALLY_VISIBLE_VERTICAL;
  }
  else {
    out |= FLAG_VISIBLE_VERTICAL;
  }

  if (innerOffsetLeft > tableWidth) {
    out |= FLAG_NOT_VISIBLE_HORIZONTAL;
  }
  else if (innerOffsetLeft + width > tableWidth) {
    this.visibilityEdgeColumnRemainder = tableWidth - innerOffsetLeft;
    out |= FLAG_PARTIALLY_VISIBLE_HORIZONTAL;
  }
  else {
    out |= FLAG_VISIBLE_HORIZONTAL;
  }

  return out;
};

/**
 * getCell
 * @param {Array} coords
 * @return {Object} HTMLElement on success or {Number} one of the exit codes on error:
 *  -1 row before viewport
 *  -2 row after viewport
 *  -3 column before viewport
 *  -4 column after viewport
 *
 */
WalkontableTable.prototype.getCell = function (coords) {
  var offsetRow = this.instance.getSetting('offsetRow');
  if (coords[0] < offsetRow) {
    return -1; //row before viewport
  }
  else if (coords[0] > offsetRow + this.instance.getSetting('displayRows') - 1) {
    return -2; //row after viewport
  }
  else {
    var offsetColumn = this.instance.getSetting('offsetColumn');
    if (coords[1] < offsetColumn) {
      return -3; //column before viewport
    }
    else if (coords[1] > offsetColumn + this.instance.getSetting('displayColumns') - 1) {
      return -4; //column after viewport
    }
    else {
      var frozenColumns = this.instance.getSetting('frozenColumns')
        , frozenColumnsCount = frozenColumns ? frozenColumns.length : 0;
      return this.TBODY.childNodes[coords[0] - offsetRow].childNodes[coords[1] - offsetColumn + frozenColumnsCount];
    }
  }
};

WalkontableTable.prototype.getCoords = function (TD) {
  var frozenColumns = this.instance.getSetting('frozenColumns')
    , frozenColumnsCount = frozenColumns ? frozenColumns.length : 0;
  return [
    this.wtDom.prevSiblings(TD.parentNode).length + this.instance.getSetting('offsetRow'),
    TD.cellIndex + this.instance.getSetting('offsetColumn') - frozenColumnsCount
  ];
};
function WalkontableWheel(instance) {
  var that = this;

  //reference to instance
  this.instance = instance;
  var wheelTimeout;
  $(this.instance.wtTable.TABLE).on('mousewheel', function (event, delta, deltaX, deltaY) {
    clearTimeout(wheelTimeout);
    wheelTimeout = setTimeout(function () { //timeout is needed because with fast-wheel scrolling mousewheel event comes dozen times per second
      if (deltaY) {
        //ceil is needed because jquery-mousewheel reports fractional mousewheel deltas on touchpad scroll
        //see http://stackoverflow.com/questions/5527601/normalizing-mousewheel-speed-across-browsers
        that.instance.scrollVertical(-Math.ceil(deltaY)).draw();
      }
      else if (deltaX) {
        that.instance.scrollHorizontal(Math.ceil(deltaX)).draw();
      }
    }, 0);
    event.preventDefault();
  });
}
/**
 * Dragdealer JS v0.9.5 - patched by Walkontable at line 66
 * http://code.ovidiu.ch/dragdealer-js
 *
 * Copyright (c) 2010, Ovidiu Chereches
 * MIT License
 * http://legal.ovidiu.ch/licenses/MIT
 */

/* Cursor */

var Cursor =
{
	x: 0, y: 0,
	init: function()
	{
		this.setEvent('mouse');
		this.setEvent('touch');
	},
	setEvent: function(type)
	{
		var moveHandler = document['on' + type + 'move'] || function(){};
		document['on' + type + 'move'] = function(e)
		{
			moveHandler(e);
			Cursor.refresh(e);
		}
	},
	refresh: function(e)
	{
		if(!e)
		{
			e = window.event;
		}
		if(e.type == 'mousemove')
		{
			this.set(e);
		}
		else if(e.touches)
		{
			this.set(e.touches[0]);
		}
	},
	set: function(e)
	{
		if(e.pageX || e.pageY)
		{
			this.x = e.pageX;
			this.y = e.pageY;
		}
		else if(e.clientX || e.clientY)
		{
			this.x = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
			this.y = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
		}
	}
};
Cursor.init();

/* Position */

var Position =
{
	get: function(obj)
	{
		var curtop = 0, curleft = 0; //Walkontable patch. Original (var curleft = curtop = 0;) created curtop in global scope
		if(obj.offsetParent)
		{
			do
			{
				curleft += obj.offsetLeft;
				curtop += obj.offsetTop;
			}
			while((obj = obj.offsetParent));
		}
		return [curleft, curtop];
	}
};

/* Dragdealer */

var Dragdealer = function(wrapper, options)
{
	if(typeof(wrapper) == 'string')
	{
		wrapper = document.getElementById(wrapper);
	}
	if(!wrapper)
	{
		return;
	}
	var handle = wrapper.getElementsByTagName('div')[0];
	if(!handle || handle.className.search(/(^|\s)handle(\s|$)/) == -1)
	{
		return;
	}
	this.init(wrapper, handle, options || {});
	this.setup();
};
Dragdealer.prototype =
{
	init: function(wrapper, handle, options)
	{
		this.wrapper = wrapper;
		this.handle = handle;
		this.options = options;
		
		this.disabled = this.getOption('disabled', false);
		this.horizontal = this.getOption('horizontal', true);
		this.vertical = this.getOption('vertical', false);
		this.slide = this.getOption('slide', true);
		this.steps = this.getOption('steps', 0);
		this.snap = this.getOption('snap', false);
		this.loose = this.getOption('loose', false);
		this.speed = this.getOption('speed', 10) / 100;
		this.xPrecision = this.getOption('xPrecision', 0);
		this.yPrecision = this.getOption('yPrecision', 0);
		
		this.callback = options.callback || null;
		this.animationCallback = options.animationCallback || null;
		
		this.bounds = {
			left: options.left || 0, right: -(options.right || 0),
			top: options.top || 0, bottom: -(options.bottom || 0),
			x0: 0, x1: 0, xRange: 0,
			y0: 0, y1: 0, yRange: 0
		};
		this.value = {
			prev: [-1, -1],
			current: [options.x || 0, options.y || 0],
			target: [options.x || 0, options.y || 0]
		};
		this.offset = {
			wrapper: [0, 0],
			mouse: [0, 0],
			prev: [-999999, -999999],
			current: [0, 0],
			target: [0, 0]
		};
		this.change = [0, 0];
		
		this.activity = false;
		this.dragging = false;
		this.tapping = false;
	},
	getOption: function(name, defaultValue)
	{
		return this.options[name] !== undefined ? this.options[name] : defaultValue;
	},
	setup: function()
	{
		this.setWrapperOffset();
		this.setBoundsPadding();
		this.setBounds();
		this.setSteps();
		
		this.addListeners();
	},
	setWrapperOffset: function()
	{
		this.offset.wrapper = Position.get(this.wrapper);
	},
	setBoundsPadding: function()
	{
		if(!this.bounds.left && !this.bounds.right)
		{
			this.bounds.left = Position.get(this.handle)[0] - this.offset.wrapper[0];
			this.bounds.right = -this.bounds.left;
		}
		if(!this.bounds.top && !this.bounds.bottom)
		{
			this.bounds.top = Position.get(this.handle)[1] - this.offset.wrapper[1];
			this.bounds.bottom = -this.bounds.top;
		}
	},
	setBounds: function()
	{
		this.bounds.x0 = this.bounds.left;
		this.bounds.x1 = this.wrapper.offsetWidth + this.bounds.right;
		this.bounds.xRange = (this.bounds.x1 - this.bounds.x0) - this.handle.offsetWidth;
		
		this.bounds.y0 = this.bounds.top;
		this.bounds.y1 = this.wrapper.offsetHeight + this.bounds.bottom;
		this.bounds.yRange = (this.bounds.y1 - this.bounds.y0) - this.handle.offsetHeight;
		
		this.bounds.xStep = 1 / (this.xPrecision || Math.max(this.wrapper.offsetWidth, this.handle.offsetWidth));
		this.bounds.yStep = 1 / (this.yPrecision || Math.max(this.wrapper.offsetHeight, this.handle.offsetHeight));
	},
	setSteps: function()
	{
		if(this.steps > 1)
		{
			this.stepRatios = [];
			for(var i = 0; i <= this.steps - 1; i++)
			{
				this.stepRatios[i] = i / (this.steps - 1);
			}
		}
	},
	addListeners: function()
	{
		var self = this;
		
		this.wrapper.onselectstart = function()
		{
			return false;
		}
		this.handle.onmousedown = this.handle.ontouchstart = function(e)
		{
			self.handleDownHandler(e);
		};
		this.wrapper.onmousedown = this.wrapper.ontouchstart = function(e)
		{
			self.wrapperDownHandler(e);
		};
		var mouseUpHandler = document.onmouseup || function(){};
		document.onmouseup = function(e)
		{
			mouseUpHandler(e);
			self.documentUpHandler(e);
		};
		var touchEndHandler = document.ontouchend || function(){};
		document.ontouchend = function(e)
		{
			touchEndHandler(e);
			self.documentUpHandler(e);
		};
		var resizeHandler = window.onresize || function(){};
		window.onresize = function(e)
		{
			resizeHandler(e);
			self.documentResizeHandler(e);
		};
		this.wrapper.onmousemove = function(e)
		{
			self.activity = true;
		}
		this.wrapper.onclick = function(e)
		{
			return !self.activity;
		}
		
		this.interval = setInterval(function(){ self.animate() }, 25);
		self.animate(false, true);
	},
	handleDownHandler: function(e)
	{
		this.activity = false;
		Cursor.refresh(e);
		
		this.preventDefaults(e, true);
		this.startDrag();
		this.cancelEvent(e);
	},
	wrapperDownHandler: function(e)
	{
		Cursor.refresh(e);
		
		this.preventDefaults(e, true);
		this.startTap();
	},
	documentUpHandler: function(e)
	{
		this.stopDrag();
		this.stopTap();
		//this.cancelEvent(e);
	},
	documentResizeHandler: function(e)
	{
		this.setWrapperOffset();
		this.setBounds();
		
		this.update();
	},
	enable: function()
	{
		this.disabled = false;
		this.handle.className = this.handle.className.replace(/\s?disabled/g, '');
	},
	disable: function()
	{
		this.disabled = true;
		this.handle.className += ' disabled';
	},
	setStep: function(x, y, snap)
	{
		this.setValue(
			this.steps && x > 1 ? (x - 1) / (this.steps - 1) : 0,
			this.steps && y > 1 ? (y - 1) / (this.steps - 1) : 0,
			snap
		);
	},
	setValue: function(x, y, snap)
	{
		this.setTargetValue([x, y || 0]);
		if(snap)
		{
			this.groupCopy(this.value.current, this.value.target);
		}
	},
	startTap: function(target)
	{
		if(this.disabled)
		{
			return;
		}
		this.tapping = true;
		
		if(target === undefined)
		{
			target = [
				Cursor.x - this.offset.wrapper[0] - (this.handle.offsetWidth / 2),
				Cursor.y - this.offset.wrapper[1] - (this.handle.offsetHeight / 2)
			];
		}
		this.setTargetOffset(target);
	},
	stopTap: function()
	{
		if(this.disabled || !this.tapping)
		{
			return;
		}
		this.tapping = false;
		
		this.setTargetValue(this.value.current);
		this.result();
	},
	startDrag: function()
	{
		if(this.disabled)
		{
			return;
		}
		this.offset.mouse = [
			Cursor.x - Position.get(this.handle)[0],
			Cursor.y - Position.get(this.handle)[1]
		];
		
		this.dragging = true;
	},
	stopDrag: function()
	{
		if(this.disabled || !this.dragging)
		{
			return;
		}
		this.dragging = false;
		
		var target = this.groupClone(this.value.current);
		if(this.slide)
		{
			var ratioChange = this.change;
			target[0] += ratioChange[0] * 4;
			target[1] += ratioChange[1] * 4;
		}
		this.setTargetValue(target);
		this.result();
	},
	feedback: function()
	{
		var value = this.value.current;
		if(this.snap && this.steps > 1)
		{
			value = this.getClosestSteps(value);
		}
		if(!this.groupCompare(value, this.value.prev))
		{
			if(typeof(this.animationCallback) == 'function')
			{
				this.animationCallback(value[0], value[1]);
			}
			this.groupCopy(this.value.prev, value);
		}
	},
	result: function()
	{
		if(typeof(this.callback) == 'function')
		{
			this.callback(this.value.target[0], this.value.target[1]);
		}
	},
	animate: function(direct, first)
	{
		if(direct && !this.dragging)
		{
			return;
		}
		if(this.dragging)
		{
			var prevTarget = this.groupClone(this.value.target);
			
			var offset = [
				Cursor.x - this.offset.wrapper[0] - this.offset.mouse[0],
				Cursor.y - this.offset.wrapper[1] - this.offset.mouse[1]
			];
			this.setTargetOffset(offset, this.loose);
			
			this.change = [
				this.value.target[0] - prevTarget[0],
				this.value.target[1] - prevTarget[1]
			];
		}
		if(this.dragging || first)
		{
			this.groupCopy(this.value.current, this.value.target);
		}
		if(this.dragging || this.glide() || first)
		{
			this.update();
			this.feedback();
		}
	},
	glide: function()
	{
		var diff = [
			this.value.target[0] - this.value.current[0],
			this.value.target[1] - this.value.current[1]
		];
		if(!diff[0] && !diff[1])
		{
			return false;
		}
		if(Math.abs(diff[0]) > this.bounds.xStep || Math.abs(diff[1]) > this.bounds.yStep)
		{
			this.value.current[0] += diff[0] * this.speed;
			this.value.current[1] += diff[1] * this.speed;
		}
		else
		{
			this.groupCopy(this.value.current, this.value.target);
		}
		return true;
	},
	update: function()
	{
		if(!this.snap)
		{
			this.offset.current = this.getOffsetsByRatios(this.value.current);
		}
		else
		{
			this.offset.current = this.getOffsetsByRatios(
				this.getClosestSteps(this.value.current)
			);
		}
		this.show();
	},
	show: function()
	{
		if(!this.groupCompare(this.offset.current, this.offset.prev))
		{
			if(this.horizontal)
			{
				this.handle.style.left = String(this.offset.current[0]) + 'px';
			}
			if(this.vertical)
			{
				this.handle.style.top = String(this.offset.current[1]) + 'px';
			}
			this.groupCopy(this.offset.prev, this.offset.current);
		}
	},
	setTargetValue: function(value, loose)
	{
		var target = loose ? this.getLooseValue(value) : this.getProperValue(value);
		
		this.groupCopy(this.value.target, target);
		this.offset.target = this.getOffsetsByRatios(target);
	},
	setTargetOffset: function(offset, loose)
	{
		var value = this.getRatiosByOffsets(offset);
		var target = loose ? this.getLooseValue(value) : this.getProperValue(value);
		
		this.groupCopy(this.value.target, target);
		this.offset.target = this.getOffsetsByRatios(target);
	},
	getLooseValue: function(value)
	{
		var proper = this.getProperValue(value);
		return [
			proper[0] + ((value[0] - proper[0]) / 4),
			proper[1] + ((value[1] - proper[1]) / 4)
		];
	},
	getProperValue: function(value)
	{
		var proper = this.groupClone(value);

		proper[0] = Math.max(proper[0], 0);
		proper[1] = Math.max(proper[1], 0);
		proper[0] = Math.min(proper[0], 1);
		proper[1] = Math.min(proper[1], 1);
		
		if((!this.dragging && !this.tapping) || this.snap)
		{
			if(this.steps > 1)
			{
				proper = this.getClosestSteps(proper);
			}
		}
		return proper;
	},
	getRatiosByOffsets: function(group)
	{
		return [
			this.getRatioByOffset(group[0], this.bounds.xRange, this.bounds.x0),
			this.getRatioByOffset(group[1], this.bounds.yRange, this.bounds.y0)
		];
	},
	getRatioByOffset: function(offset, range, padding)
	{
		return range ? (offset - padding) / range : 0;
	},
	getOffsetsByRatios: function(group)
	{
		return [
			this.getOffsetByRatio(group[0], this.bounds.xRange, this.bounds.x0),
			this.getOffsetByRatio(group[1], this.bounds.yRange, this.bounds.y0)
		];
	},
	getOffsetByRatio: function(ratio, range, padding)
	{
		return Math.round(ratio * range) + padding;
	},
	getClosestSteps: function(group)
	{
		return [
			this.getClosestStep(group[0]),
			this.getClosestStep(group[1])
		];
	},
	getClosestStep: function(value)
	{
		var k = 0;
		var min = 1;
		for(var i = 0; i <= this.steps - 1; i++)
		{
			if(Math.abs(this.stepRatios[i] - value) < min)
			{
				min = Math.abs(this.stepRatios[i] - value);
				k = i;
			}
		}
		return this.stepRatios[k];
	},
	groupCompare: function(a, b)
	{
		return a[0] == b[0] && a[1] == b[1];
	},
	groupCopy: function(a, b)
	{
		a[0] = b[0];
		a[1] = b[1];
	},
	groupClone: function(a)
	{
		return [a[0], a[1]];
	},
	preventDefaults: function(e, selection)
	{
		if(!e)
		{
			e = window.event;
		}
		if(e.preventDefault)
		{
			e.preventDefault();
		}
		e.returnValue = false;
		
		if(selection && document.selection)
		{
			document.selection.empty();
		}
	},
	cancelEvent: function(e)
	{
		if(!e)
		{
			e = window.event;
		}
		if(e.stopPropagation)
		{
			e.stopPropagation();
		}
		e.cancelBubble = true;
	}
};

/*! Copyright (c) 2011 Brandon Aaron (http://brandonaaron.net)
 * Licensed under the MIT License (LICENSE.txt).
 *
 * Thanks to: http://adomas.org/javascript-mouse-wheel/ for some pointers.
 * Thanks to: Mathias Bank(http://www.mathias-bank.de) for a scope bug fix.
 * Thanks to: Seamus Leahy for adding deltaX and deltaY
 *
 * Version: 3.0.6
 * 
 * Requires: 1.2.2+
 */

(function($) {

var types = ['DOMMouseScroll', 'mousewheel'];

if ($.event.fixHooks) {
    for ( var i=types.length; i; ) {
        $.event.fixHooks[ types[--i] ] = $.event.mouseHooks;
    }
}

$.event.special.mousewheel = {
    setup: function() {
        if ( this.addEventListener ) {
            for ( var i=types.length; i; ) {
                this.addEventListener( types[--i], handler, false );
            }
        } else {
            this.onmousewheel = handler;
        }
    },
    
    teardown: function() {
        if ( this.removeEventListener ) {
            for ( var i=types.length; i; ) {
                this.removeEventListener( types[--i], handler, false );
            }
        } else {
            this.onmousewheel = null;
        }
    }
};

$.fn.extend({
    mousewheel: function(fn) {
        return fn ? this.bind("mousewheel", fn) : this.trigger("mousewheel");
    },
    
    unmousewheel: function(fn) {
        return this.unbind("mousewheel", fn);
    }
});


function handler(event) {
    var orgEvent = event || window.event, args = [].slice.call( arguments, 1 ), delta = 0, returnValue = true, deltaX = 0, deltaY = 0;
    event = $.event.fix(orgEvent);
    event.type = "mousewheel";
    
    // Old school scrollwheel delta
    if ( orgEvent.wheelDelta ) { delta = orgEvent.wheelDelta/120; }
    if ( orgEvent.detail     ) { delta = -orgEvent.detail/3; }
    
    // New school multidimensional scroll (touchpads) deltas
    deltaY = delta;
    
    // Gecko
    if ( orgEvent.axis !== undefined && orgEvent.axis === orgEvent.HORIZONTAL_AXIS ) {
        deltaY = 0;
        deltaX = -1*delta;
    }
    
    // Webkit
    if ( orgEvent.wheelDeltaY !== undefined ) { deltaY = orgEvent.wheelDeltaY/120; }
    if ( orgEvent.wheelDeltaX !== undefined ) { deltaX = -1*orgEvent.wheelDeltaX/120; }
    
    // Add event and delta to the front of the arguments
    args.unshift(event, delta, deltaX, deltaY);
    
    return ($.event.dispatch || $.event.handle).apply(this, args);
}

})(jQuery);

})(jQuery, window, Handsontable);
/* =============================================================
 * bootstrap-typeahead.js v2.1.1
 * http://twitter.github.com/bootstrap/javascript.html#typeahead
 * =============================================================
 * Copyright 2012 Twitter, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ============================================================ */


!function($){

  "use strict"; // jshint ;_;


 /* TYPEAHEAD PUBLIC CLASS DEFINITION
  * ================================= */

  var Typeahead = function (element, options) {
    this.$element = $(element)
    this.options = $.extend({}, $.fn.typeahead.defaults, options)
    this.matcher = this.options.matcher || this.matcher
    this.sorter = this.options.sorter || this.sorter
    this.highlighter = this.options.highlighter || this.highlighter
    this.updater = this.options.updater || this.updater
    this.$menu = $(this.options.menu).appendTo('body')
    this.source = this.options.source
    this.shown = false
    this.listen()
  }

  Typeahead.prototype = {

    constructor: Typeahead

  , select: function () {
      var val = this.$menu.find('.active').attr('data-value')
      this.$element
        .val(this.updater(val))
        .change()
      return this.hide()
    }

  , updater: function (item) {
      return item
    }

  , show: function () {
      var pos = $.extend({}, this.$element.offset(), {
        height: this.$element[0].offsetHeight
      })

      this.$menu.css({
        top: pos.top + pos.height
      , left: pos.left
      })

      this.$menu.show()
      this.shown = true
      return this
    }

  , hide: function () {
      this.$menu.hide()
      this.shown = false
      return this
    }

  , lookup: function (event) {
      var items

      this.query = this.$element.val()

      if (!this.query || this.query.length < this.options.minLength) {
        return this.shown ? this.hide() : this
      }

      items = $.isFunction(this.source) ? this.source(this.query, $.proxy(this.process, this)) : this.source

      return items ? this.process(items) : this
    }

  , process: function (items) {
      var that = this

      items = $.grep(items, function (item) {
        return that.matcher(item)
      })

      items = this.sorter(items)

      if (!items.length) {
        return this.shown ? this.hide() : this
      }

      return this.render(items.slice(0, this.options.items)).show()
    }

  , matcher: function (item) {
      return ~item.toLowerCase().indexOf(this.query.toLowerCase())
    }

  , sorter: function (items) {
      var beginswith = []
        , caseSensitive = []
        , caseInsensitive = []
        , item

      while (item = items.shift()) {
        if (!item.toLowerCase().indexOf(this.query.toLowerCase())) beginswith.push(item)
        else if (~item.indexOf(this.query)) caseSensitive.push(item)
        else caseInsensitive.push(item)
      }

      return beginswith.concat(caseSensitive, caseInsensitive)
    }

  , highlighter: function (item) {
      var query = this.query.replace(/[\-\[\]{}()*+?.,\\\^$|#\s]/g, '\\$&')
      return item.replace(new RegExp('(' + query + ')', 'ig'), function ($1, match) {
        return '<strong>' + match + '</strong>'
      })
    }

  , render: function (items) {
      var that = this

      items = $(items).map(function (i, item) {
        i = $(that.options.item).attr('data-value', item)
        i.find('a').html(that.highlighter(item))
        return i[0]
      })

      items.first().addClass('active')
      this.$menu.html(items)
      return this
    }

  , next: function (event) {
      var active = this.$menu.find('.active').removeClass('active')
        , next = active.next()

      if (!next.length) {
        next = $(this.$menu.find('li')[0])
      }

      next.addClass('active')
    }

  , prev: function (event) {
      var active = this.$menu.find('.active').removeClass('active')
        , prev = active.prev()

      if (!prev.length) {
        prev = this.$menu.find('li').last()
      }

      prev.addClass('active')
    }

  , listen: function () {
      this.$element
        .on('blur',     $.proxy(this.blur, this))
        .on('keypress', $.proxy(this.keypress, this))
        .on('keyup',    $.proxy(this.keyup, this))

      if ($.browser.chrome || $.browser.webkit || $.browser.msie) {
        this.$element.on('keydown', $.proxy(this.keydown, this))
      }

      this.$menu
        .on('click', $.proxy(this.click, this))
        .on('mouseenter', 'li', $.proxy(this.mouseenter, this))
    }

  , move: function (e) {
      if (!this.shown) return

      switch(e.keyCode) {
        case 9: // tab
        case 13: // enter
        case 27: // escape
          e.preventDefault()
          break

        case 38: // up arrow
          e.preventDefault()
          this.prev()
          break

        case 40: // down arrow
          e.preventDefault()
          this.next()
          break
      }

      e.stopPropagation()
    }

  , keydown: function (e) {
      this.suppressKeyPressRepeat = !~$.inArray(e.keyCode, [40,38,9,13,27])
      this.move(e)
    }

  , keypress: function (e) {
      if (this.suppressKeyPressRepeat) return
      this.move(e)
    }

  , keyup: function (e) {
      switch(e.keyCode) {
        case 40: // down arrow
        case 38: // up arrow
          break

        case 9: // tab
        case 13: // enter
          if (!this.shown) return
          this.select()
          break

        case 27: // escape
          if (!this.shown) return
          this.hide()
          break

        default:
          this.lookup()
      }

      e.stopPropagation()
      e.preventDefault()
  }

  , blur: function (e) {
      var that = this
      setTimeout(function () { that.hide() }, 150)
    }

  , click: function (e) {
      e.stopPropagation()
      e.preventDefault()
      this.select()
    }

  , mouseenter: function (e) {
      this.$menu.find('.active').removeClass('active')
      $(e.currentTarget).addClass('active')
    }

  }


  /* TYPEAHEAD PLUGIN DEFINITION
   * =========================== */

  $.fn.typeahead = function (option) {
    return this.each(function () {
      var $this = $(this)
        , data = $this.data('typeahead')
        , options = typeof option == 'object' && option
      if (!data) $this.data('typeahead', (data = new Typeahead(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  $.fn.typeahead.defaults = {
    source: []
  , items: 8
  , menu: '<ul class="typeahead dropdown-menu"></ul>'
  , item: '<li><a href="#"></a></li>'
  , minLength: 1
  }

  $.fn.typeahead.Constructor = Typeahead


 /*   TYPEAHEAD DATA-API
  * ================== */

  $(function () {
    $('body').on('focus.typeahead.data-api', '[data-provide="typeahead"]', function (e) {
      var $this = $(this)
      if ($this.data('typeahead')) return
      e.preventDefault()
      $this.typeahead($this.data())
    })
  })

}(window.jQuery);
/*!
 * jQuery contextMenu - Plugin for simple contextMenu handling
 *
 * Version: 1.5.25
 *
 * Authors: Rodney Rehm, Addy Osmani (patches for FF)
 * Web: http://medialize.github.com/jQuery-contextMenu/
 *
 * Licensed under
 *   MIT License http://www.opensource.org/licenses/mit-license
 *   GPL v3 http://opensource.org/licenses/GPL-3.0
 *
 */

(function($, undefined){
    
    // TODO: -
        // ARIA stuff: menuitem, menuitemcheckbox und menuitemradio
        // create <menu> structure if $.support[htmlCommand || htmlMenuitem] and !opt.disableNative

// determine html5 compatibility
$.support.htmlMenuitem = ('HTMLMenuItemElement' in window);
$.support.htmlCommand = ('HTMLCommandElement' in window);
$.support.eventSelectstart = ("onselectstart" in document.documentElement);
/* // should the need arise, test for css user-select
$.support.cssUserSelect = (function(){
    var t = false,
        e = document.createElement('div');
    
    $.each('Moz|Webkit|Khtml|O|ms|Icab|'.split('|'), function(i, prefix) {
        var propCC = prefix + (prefix ? 'U' : 'u') + 'serSelect',
            prop = (prefix ? ('-' + prefix.toLowerCase() + '-') : '') + 'user-select';
            
        e.style.cssText = prop + ': text;';
        if (e.style[propCC] == 'text') {
            t = true;
            return false;
        }
        
        return true;
    });
    
    return t;
})();
*/

var // currently active contextMenu trigger
    $currentTrigger = null,
    // is contextMenu initialized with at least one menu?
    initialized = false,
    // window handle
    $win = $(window),
    // number of registered menus
    counter = 0,
    // mapping selector to namespace
    namespaces = {},
    // mapping namespace to options
    menus = {},
    // custom command type handlers
    types = {},
    // default values
    defaults = {
        // selector of contextMenu trigger
        selector: null,
        // where to append the menu to
        appendTo: null,
        // method to trigger context menu ["right", "left", "hover"]
        trigger: "right",
        // hide menu when mouse leaves trigger / menu elements
        autoHide: false,
        // ms to wait before showing a hover-triggered context menu
        delay: 200,
        // determine position to show menu at
        determinePosition: function($menu) {
            // position to the lower middle of the trigger element
            if ($.ui && $.ui.position) {
                // .position() is provided as a jQuery UI utility
                // (...and it won't work on hidden elements)
                $menu.css('display', 'block').position({
                    my: "center top",
                    at: "center bottom",
                    of: this,
                    offset: "0 5",
                    collision: "fit"
                }).css('display', 'none');
            } else {
                // determine contextMenu position
                var offset = this.offset();
                offset.top += this.outerHeight();
                offset.left += this.outerWidth() / 2 - $menu.outerWidth() / 2;
                $menu.css(offset);
            }
        },
        // position menu
        position: function(opt, x, y) {
            var $this = this,
                offset;
            // determine contextMenu position
            if (!x && !y) {
                opt.determinePosition.call(this, opt.$menu);
                return;
            } else if (x === "maintain" && y === "maintain") {
                // x and y must not be changed (after re-show on command click)
                offset = opt.$menu.position();
            } else {
                // x and y are given (by mouse event)
                var triggerIsFixed = opt.$trigger.parents().andSelf()
                    .filter(function() {
                        return $(this).css('position') == "fixed";
                    }).length;

                if (triggerIsFixed) {
                    y -= $win.scrollTop();
                    x -= $win.scrollLeft();
                }
                offset = {top: y, left: x};
            }
            
            // correct offset if viewport demands it
            var bottom = $win.scrollTop() + $win.height(),
                right = $win.scrollLeft() + $win.width(),
                height = opt.$menu.height(),
                width = opt.$menu.width();
            
            if (offset.top + height > bottom) {
                offset.top -= height;
            }
            
            if (offset.left + width > right) {
                offset.left -= width;
            }
            
            opt.$menu.css(offset);
        },
        // position the sub-menu
        positionSubmenu: function($menu) {
            if ($.ui && $.ui.position) {
                // .position() is provided as a jQuery UI utility
                // (...and it won't work on hidden elements)
                $menu.css('display', 'block').position({
                    my: "left top",
                    at: "right top",
                    of: this,
                    collision: "fit"
                }).css('display', '');
            } else {
                // determine contextMenu position
                var offset = {
                    top: 0,
                    left: this.outerWidth()
                };
                $menu.css(offset);
            }
        },
        // offset to add to zIndex
        zIndex: 1,
        // show hide animation settings
        animation: {
            duration: 50,
            show: 'slideDown',
            hide: 'slideUp'
        },
        // events
        events: {
            show: $.noop,
            hide: $.noop
        },
        // default callback
        callback: null,
        // list of contextMenu items
        items: {}
    },
    // mouse position for hover activation
    hoveract = {
        timer: null,
        pageX: null,
        pageY: null
    },
    // determine zIndex
    zindex = function($t) {
        var zin = 0,
            $tt = $t;

        while (true) {
            zin = Math.max(zin, parseInt($tt.css('z-index'), 10) || 0);
            $tt = $tt.parent();
            if (!$tt || !$tt.length || "html body".indexOf($tt.prop('nodeName').toLowerCase()) > -1 ) {
                break;
            }
        }
        
        return zin;
    },
    // event handlers
    handle = {
        // abort anything
        abortevent: function(e){
            e.preventDefault();
            e.stopImmediatePropagation();
        },
        
        // contextmenu show dispatcher
        contextmenu: function(e) {
            var $this = $(this);
            
            // disable actual context-menu
            e.preventDefault();
            e.stopImmediatePropagation();
            
            // abort native-triggered events unless we're triggering on right click
            if (e.data.trigger != 'right' && e.originalEvent) {
                return;
            }
            
            if (!$this.hasClass('context-menu-disabled')) {
                // theoretically need to fire a show event at <menu>
                // http://www.whatwg.org/specs/web-apps/current-work/multipage/interactive-elements.html#context-menus
                // var evt = jQuery.Event("show", { data: data, pageX: e.pageX, pageY: e.pageY, relatedTarget: this });
                // e.data.$menu.trigger(evt);
                
                $currentTrigger = $this;
                if (e.data.build) {
                    var built = e.data.build($currentTrigger, e);
                    // abort if build() returned false
                    if (built === false) {
                        return;
                    }
                    
                    // dynamically build menu on invocation
                    e.data = $.extend(true, {}, defaults, e.data, built || {});

                    // abort if there are no items to display
                    if (!e.data.items || $.isEmptyObject(e.data.items)) {
                        // Note: jQuery captures and ignores errors from event handlers
                        if (window.console) {
                            (console.error || console.log)("No items specified to show in contextMenu");
                        }
                        
                        throw new Error('No Items sepcified');
                    }
                    
                    // backreference for custom command type creation
                    e.data.$trigger = $currentTrigger;
                    
                    op.create(e.data);
                }
                // show menu
                op.show.call($this, e.data, e.pageX, e.pageY);
            }
        },
        // contextMenu left-click trigger
        click: function(e) {
            e.preventDefault();
            e.stopImmediatePropagation();
            $(this).trigger($.Event("contextmenu", { data: e.data, pageX: e.pageX, pageY: e.pageY }));
        },
        // contextMenu right-click trigger
        mousedown: function(e) {
            // register mouse down
            var $this = $(this);
            
            // hide any previous menus
            if ($currentTrigger && $currentTrigger.length && !$currentTrigger.is($this)) {
                $currentTrigger.data('contextMenu').$menu.trigger('contextmenu:hide');
            }
            
            // activate on right click
            if (e.button == 2) {
                $currentTrigger = $this.data('contextMenuActive', true);
            }
        },
        // contextMenu right-click trigger
        mouseup: function(e) {
            // show menu
            var $this = $(this);
            if ($this.data('contextMenuActive') && $currentTrigger && $currentTrigger.length && $currentTrigger.is($this) && !$this.hasClass('context-menu-disabled')) {
                e.preventDefault();
                e.stopImmediatePropagation();
                $currentTrigger = $this;
                $this.trigger($.Event("contextmenu", { data: e.data, pageX: e.pageX, pageY: e.pageY }));
            }
            
            $this.removeData('contextMenuActive');
        },
        // contextMenu hover trigger
        mouseenter: function(e) {
            var $this = $(this),
                $related = $(e.relatedTarget),
                $document = $(document);
            
            // abort if we're coming from a menu
            if ($related.is('.context-menu-list') || $related.closest('.context-menu-list').length) {
                return;
            }
            
            // abort if a menu is shown
            if ($currentTrigger && $currentTrigger.length) {
                return;
            }
            
            hoveract.pageX = e.pageX;
            hoveract.pageY = e.pageY;
            hoveract.data = e.data;
            $document.on('mousemove.contextMenuShow', handle.mousemove);
            hoveract.timer = setTimeout(function() {
                hoveract.timer = null;
                $document.off('mousemove.contextMenuShow');
                $currentTrigger = $this;
                $this.trigger($.Event("contextmenu", { data: hoveract.data, pageX: hoveract.pageX, pageY: hoveract.pageY }));
            }, e.data.delay );
        },
        // contextMenu hover trigger
        mousemove: function(e) {
            hoveract.pageX = e.pageX;
            hoveract.pageY = e.pageY;
        },
        // contextMenu hover trigger
        mouseleave: function(e) {
            // abort if we're leaving for a menu
            var $related = $(e.relatedTarget);
            if ($related.is('.context-menu-list') || $related.closest('.context-menu-list').length) {
                return;
            }
            
            try {
                clearTimeout(hoveract.timer);
            } catch(e) {}
            
            hoveract.timer = null;
        },
        
        // click on layer to hide contextMenu
        layerClick: function(e) {
            var $this = $(this),
                root = $this.data('contextMenuRoot'),
                mouseup = false,
                button = e.button,
                x = e.pageX,
                y = e.pageY,
                target, 
                offset,
                selectors;
                
            e.preventDefault();
            e.stopImmediatePropagation();
            
            // This hack looks about as ugly as it is
            // Firefox 12 (at least) fires the contextmenu event directly "after" mousedown
            // for some reason `root.$layer.hide(); document.elementFromPoint()` causes this
            // contextmenu event to be triggered on the uncovered element instead of on the
            // layer (where every other sane browser, including Firefox nightly at the time)
            // triggers the event. This workaround might be obsolete by September 2012.
            $this.on('mouseup', function() {
                mouseup = true;
            });
            setTimeout(function() {
                var $window, hideshow;
                // test if we need to reposition the menu
                if ((root.trigger == 'left' && button == 0) || (root.trigger == 'right' && button == 2)) {
                    if (document.elementFromPoint) {
                        root.$layer.hide();
                        target = document.elementFromPoint(x - $win.scrollLeft(), y - $win.scrollTop());
                        root.$layer.show();

                        selectors = [];
                        for (var s in namespaces) {
                            selectors.push(s);
                        }

                        target = $(target).closest(selectors.join(', '));

                        if (target.length) {
                            if (target.is(root.$trigger[0])) {
                                root.position.call(root.$trigger, root, x, y);
                                return;
                            }
                        }
                    } else {
                        offset = root.$trigger.offset();
                        $window = $(window);
                        // while this looks kinda awful, it's the best way to avoid
                        // unnecessarily calculating any positions
                        offset.top += $window.scrollTop();
                        if (offset.top <= e.pageY) {
                            offset.left += $window.scrollLeft();
                            if (offset.left <= e.pageX) {
                                offset.bottom = offset.top + root.$trigger.outerHeight();
                                if (offset.bottom >= e.pageY) {
                                    offset.right = offset.left + root.$trigger.outerWidth();
                                    if (offset.right >= e.pageX) {
                                        // reposition
                                        root.position.call(root.$trigger, root, x, y);
                                        return;
                                    }
                                }
                            }
                        }
                    }
                }

                hideshow = function(e) {
                    if (e) {
                        e.preventDefault();
                        e.stopImmediatePropagation();
                    }

                    root.$menu.trigger('contextmenu:hide');
                    if (target && target.length) {
                        setTimeout(function() {
                            target.contextMenu({x: x, y: y});
                        }, 50);
                    }
                };
            
                if (mouseup) {
                    // mouseup has already happened
                    hideshow();
                } else {
                    // remove only after mouseup has completed
                    $this.on('mouseup', hideshow);
                }
            }, 50);
        },
        // key handled :hover
        keyStop: function(e, opt) {
            if (!opt.isInput) {
                e.preventDefault();
            }
            
            e.stopPropagation();
        },
        key: function(e) {
            var opt = $currentTrigger.data('contextMenu') || {},
                $children = opt.$menu.children(),
                $round;

            switch (e.keyCode) {
                case 9:
                case 38: // up
                    handle.keyStop(e, opt);
                    // if keyCode is [38 (up)] or [9 (tab) with shift]
                    if (opt.isInput) {
                        if (e.keyCode == 9 && e.shiftKey) {
                            e.preventDefault();
                            opt.$selected && opt.$selected.find('input, textarea, select').blur();
                            opt.$menu.trigger('prevcommand');
                            return;
                        } else if (e.keyCode == 38 && opt.$selected.find('input, textarea, select').prop('type') == 'checkbox') {
                            // checkboxes don't capture this key
                            e.preventDefault();
                            return;
                        }
                    } else if (e.keyCode != 9 || e.shiftKey) {
                        opt.$menu.trigger('prevcommand');
                        return;
                    }
                    // omitting break;
                    
                // case 9: // tab - reached through omitted break;
                case 40: // down
                    handle.keyStop(e, opt);
                    if (opt.isInput) {
                        if (e.keyCode == 9) {
                            e.preventDefault();
                            opt.$selected && opt.$selected.find('input, textarea, select').blur();
                            opt.$menu.trigger('nextcommand');
                            return;
                        } else if (e.keyCode == 40 && opt.$selected.find('input, textarea, select').prop('type') == 'checkbox') {
                            // checkboxes don't capture this key
                            e.preventDefault();
                            return;
                        }
                    } else {
                        opt.$menu.trigger('nextcommand');
                        return;
                    }
                    break;
                
                case 37: // left
                    handle.keyStop(e, opt);
                    if (opt.isInput || !opt.$selected || !opt.$selected.length) {
                        break;
                    }
                
                    if (!opt.$selected.parent().hasClass('context-menu-root')) {
                        var $parent = opt.$selected.parent().parent();
                        opt.$selected.trigger('contextmenu:blur');
                        opt.$selected = $parent;
                        return;
                    }
                    break;
                    
                case 39: // right
                    handle.keyStop(e, opt);
                    if (opt.isInput || !opt.$selected || !opt.$selected.length) {
                        break;
                    }
                    
                    var itemdata = opt.$selected.data('contextMenu') || {};
                    if (itemdata.$menu && opt.$selected.hasClass('context-menu-submenu')) {
                        opt.$selected = null;
                        itemdata.$selected = null;
                        itemdata.$menu.trigger('nextcommand');
                        return;
                    }
                    break;
                
                case 35: // end
                case 36: // home
                    if (opt.$selected && opt.$selected.find('input, textarea, select').length) {
                        return;
                    } else {
                        (opt.$selected && opt.$selected.parent() || opt.$menu)
                            .children(':not(.disabled, .not-selectable)')[e.keyCode == 36 ? 'first' : 'last']()
                            .trigger('contextmenu:focus');
                        e.preventDefault();
                        return;
                    }
                    break;
                    
                case 13: // enter
                    handle.keyStop(e, opt);
                    if (opt.isInput) {
                        if (opt.$selected && !opt.$selected.is('textarea, select')) {
                            e.preventDefault();
                            return;
                        }
                        break;
                    }
                    opt.$selected && opt.$selected.trigger('mouseup');
                    return;
                    
                case 32: // space
                case 33: // page up
                case 34: // page down
                    // prevent browser from scrolling down while menu is visible
                    handle.keyStop(e, opt);
                    return;
                    
                case 27: // esc
                    handle.keyStop(e, opt);
                    opt.$menu.trigger('contextmenu:hide');
                    return;
                    
                default: // 0-9, a-z
                    var k = (String.fromCharCode(e.keyCode)).toUpperCase();
                    if (opt.accesskeys[k]) {
                        // according to the specs accesskeys must be invoked immediately
                        opt.accesskeys[k].$node.trigger(opt.accesskeys[k].$menu
                            ? 'contextmenu:focus'
                            : 'mouseup'
                        );
                        return;
                    }
                    break;
            }
            // pass event to selected item, 
            // stop propagation to avoid endless recursion
            e.stopPropagation();
            opt.$selected && opt.$selected.trigger(e);
        },

        // select previous possible command in menu
        prevItem: function(e) {
            e.stopPropagation();
            var opt = $(this).data('contextMenu') || {};

            // obtain currently selected menu
            if (opt.$selected) {
                var $s = opt.$selected;
                opt = opt.$selected.parent().data('contextMenu') || {};
                opt.$selected = $s;
            }
            
            var $children = opt.$menu.children(),
                $prev = !opt.$selected || !opt.$selected.prev().length ? $children.last() : opt.$selected.prev(),
                $round = $prev;
            
            // skip disabled
            while ($prev.hasClass('disabled') || $prev.hasClass('not-selectable')) {
                if ($prev.prev().length) {
                    $prev = $prev.prev();
                } else {
                    $prev = $children.last();
                }
                if ($prev.is($round)) {
                    // break endless loop
                    return;
                }
            }
            
            // leave current
            if (opt.$selected) {
                handle.itemMouseleave.call(opt.$selected.get(0), e);
            }
            
            // activate next
            handle.itemMouseenter.call($prev.get(0), e);
            
            // focus input
            var $input = $prev.find('input, textarea, select');
            if ($input.length) {
                $input.focus();
            }
        },
        // select next possible command in menu
        nextItem: function(e) {
            e.stopPropagation();
            var opt = $(this).data('contextMenu') || {};

            // obtain currently selected menu
            if (opt.$selected) {
                var $s = opt.$selected;
                opt = opt.$selected.parent().data('contextMenu') || {};
                opt.$selected = $s;
            }

            var $children = opt.$menu.children(),
                $next = !opt.$selected || !opt.$selected.next().length ? $children.first() : opt.$selected.next(),
                $round = $next;

            // skip disabled
            while ($next.hasClass('disabled') || $next.hasClass('not-selectable')) {
                if ($next.next().length) {
                    $next = $next.next();
                } else {
                    $next = $children.first();
                }
                if ($next.is($round)) {
                    // break endless loop
                    return;
                }
            }
            
            // leave current
            if (opt.$selected) {
                handle.itemMouseleave.call(opt.$selected.get(0), e);
            }
            
            // activate next
            handle.itemMouseenter.call($next.get(0), e);
            
            // focus input
            var $input = $next.find('input, textarea, select');
            if ($input.length) {
                $input.focus();
            }
        },
        
        // flag that we're inside an input so the key handler can act accordingly
        focusInput: function(e) {
            var $this = $(this).closest('.context-menu-item'),
                data = $this.data(),
                opt = data.contextMenu,
                root = data.contextMenuRoot;

            root.$selected = opt.$selected = $this;
            root.isInput = opt.isInput = true;
        },
        // flag that we're inside an input so the key handler can act accordingly
        blurInput: function(e) {
            var $this = $(this).closest('.context-menu-item'),
                data = $this.data(),
                opt = data.contextMenu,
                root = data.contextMenuRoot;

            root.isInput = opt.isInput = false;
        },
        
        // :hover on menu
        menuMouseenter: function(e) {
            var root = $(this).data().contextMenuRoot;
            root.hovering = true;
        },
        // :hover on menu
        menuMouseleave: function(e) {
            var root = $(this).data().contextMenuRoot;
            if (root.$layer && root.$layer.is(e.relatedTarget)) {
                root.hovering = false;
            }
        },
        
        // :hover done manually so key handling is possible
        itemMouseenter: function(e) {
            var $this = $(this),
                data = $this.data(),
                opt = data.contextMenu,
                root = data.contextMenuRoot;
            
            root.hovering = true;

            // abort if we're re-entering
            if (e && root.$layer && root.$layer.is(e.relatedTarget)) {
                e.preventDefault();
                e.stopImmediatePropagation();
            }

            // make sure only one item is selected
            (opt.$menu ? opt : root).$menu
                .children('.hover').trigger('contextmenu:blur');

            if ($this.hasClass('disabled') || $this.hasClass('not-selectable')) {
                opt.$selected = null;
                return;
            }
            
            $this.trigger('contextmenu:focus');
        },
        // :hover done manually so key handling is possible
        itemMouseleave: function(e) {
            var $this = $(this),
                data = $this.data(),
                opt = data.contextMenu,
                root = data.contextMenuRoot;

            if (root !== opt && root.$layer && root.$layer.is(e.relatedTarget)) {
                root.$selected && root.$selected.trigger('contextmenu:blur');
                e.preventDefault();
                e.stopImmediatePropagation();
                root.$selected = opt.$selected = opt.$node;
                return;
            }
            
            $this.trigger('contextmenu:blur');
        },
        // contextMenu item click
        itemClick: function(e) {
            var $this = $(this),
                data = $this.data(),
                opt = data.contextMenu,
                root = data.contextMenuRoot,
                key = data.contextMenuKey,
                callback;

            // abort if the key is unknown or disabled or is a menu
            if (!opt.items[key] || $this.hasClass('disabled') || $this.hasClass('context-menu-submenu')) {
                return;
            }

            e.preventDefault();
            e.stopImmediatePropagation();

            if ($.isFunction(root.callbacks[key])) {
                // item-specific callback
                callback = root.callbacks[key];
            } else if ($.isFunction(root.callback)) {
                // default callback
                callback = root.callback;                
            } else {
                // no callback, no action
                return;
            }

            // hide menu if callback doesn't stop that
            if (callback.call(root.$trigger, key, root) !== false) {
                root.$menu.trigger('contextmenu:hide');
            } else if (root.$menu.parent().length) {
                op.update.call(root.$trigger, root);
            }
        },
        // ignore click events on input elements
        inputClick: function(e) {
            e.stopImmediatePropagation();
        },
        
        // hide <menu>
        hideMenu: function(e, data) {
            var root = $(this).data('contextMenuRoot');
            op.hide.call(root.$trigger, root, data && data.force);
        },
        // focus <command>
        focusItem: function(e) {
            e.stopPropagation();
            var $this = $(this),
                data = $this.data(),
                opt = data.contextMenu,
                root = data.contextMenuRoot;

            $this.addClass('hover')
                .siblings('.hover').trigger('contextmenu:blur');
            
            // remember selected
            opt.$selected = root.$selected = $this;
            
            // position sub-menu - do after show so dumb $.ui.position can keep up
            if (opt.$node) {
                root.positionSubmenu.call(opt.$node, opt.$menu);
            }
        },
        // blur <command>
        blurItem: function(e) {
            e.stopPropagation();
            var $this = $(this),
                data = $this.data(),
                opt = data.contextMenu,
                root = data.contextMenuRoot;
            
            $this.removeClass('hover');
            opt.$selected = null;
        }
    },
    // operations
    op = {
        show: function(opt, x, y) {
            var $this = $(this),
                offset,
                css = {};

            // hide any open menus
            $('#context-menu-layer').trigger('mousedown');

            // backreference for callbacks
            opt.$trigger = $this;

            // show event
            if (opt.events.show.call($this, opt) === false) {
                $currentTrigger = null;
                return;
            }

            // create or update context menu
            op.update.call($this, opt);
            
            // position menu
            opt.position.call($this, opt, x, y);

            // make sure we're in front
            if (opt.zIndex) {
                css.zIndex = zindex($this) + opt.zIndex;
            }
            
            // add layer
            op.layer.call(opt.$menu, opt, css.zIndex);
            
            // adjust sub-menu zIndexes
            opt.$menu.find('ul').css('zIndex', css.zIndex + 1);
            
            // position and show context menu
            opt.$menu.css( css )[opt.animation.show](opt.animation.duration);
            // make options available
            $this.data('contextMenu', opt);
            // register key handler
            $(document).off('keydown.contextMenu').on('keydown.contextMenu', handle.key);
            // register autoHide handler
            if (opt.autoHide) {
                // trigger element coordinates
                var pos = $this.position();
                pos.right = pos.left + $this.outerWidth();
                pos.bottom = pos.top + this.outerHeight();
                // mouse position handler
                $(document).on('mousemove.contextMenuAutoHide', function(e) {
                    if (opt.$layer && !opt.hovering && (!(e.pageX >= pos.left && e.pageX <= pos.right) || !(e.pageY >= pos.top && e.pageY <= pos.bottom))) {
                        // if mouse in menu...
                        opt.$menu.trigger('contextmenu:hide');
                    }
                });
            }
        },
        hide: function(opt, force) {
            var $this = $(this);
            if (!opt) {
                opt = $this.data('contextMenu') || {};
            }
            
            // hide event
            if (!force && opt.events && opt.events.hide.call($this, opt) === false) {
                return;
            }
            
            if (opt.$layer) {
                // keep layer for a bit so the contextmenu event can be aborted properly by opera
                setTimeout((function($layer){ return function(){
                        $layer.remove();
                    };
                })(opt.$layer), 10);
                
                try {
                    delete opt.$layer;
                } catch(e) {
                    opt.$layer = null;
                }
            }
            
            // remove handle
            $currentTrigger = null;
            // remove selected
            opt.$menu.find('.hover').trigger('contextmenu:blur');
            opt.$selected = null;
            // unregister key and mouse handlers
            //$(document).off('.contextMenuAutoHide keydown.contextMenu'); // http://bugs.jquery.com/ticket/10705
            $(document).off('.contextMenuAutoHide').off('keydown.contextMenu');
            // hide menu
            opt.$menu && opt.$menu[opt.animation.hide](opt.animation.duration, function (){
                // tear down dynamically built menu after animation is completed.
                if (opt.build) {
                    opt.$menu.remove();
                    $.each(opt, function(key, value) {
                        switch (key) {
                            case 'ns':
                            case 'selector':
                            case 'build':
                            case 'trigger':
                                return true;

                            default:
                                opt[key] = undefined;
                                try {
                                    delete opt[key];
                                } catch (e) {}
                                return true;
                        }
                    });
                }
            });
        },
        create: function(opt, root) {
            if (root === undefined) {
                root = opt;
            }
            // create contextMenu
            opt.$menu = $('<ul class="context-menu-list ' + (opt.className || "") + '"></ul>').data({
                'contextMenu': opt,
                'contextMenuRoot': root
            });
            
            $.each(['callbacks', 'commands', 'inputs'], function(i,k){
                opt[k] = {};
                if (!root[k]) {
                    root[k] = {};
                }
            });
            
            root.accesskeys || (root.accesskeys = {});
            
            // create contextMenu items
            $.each(opt.items, function(key, item){
                var $t = $('<li class="context-menu-item ' + (item.className || "") +'"></li>'),
                    $label = null,
                    $input = null;
                
                item.$node = $t.data({
                    'contextMenu': opt,
                    'contextMenuRoot': root,
                    'contextMenuKey': key
                });
                
                // register accesskey
                // NOTE: the accesskey attribute should be applicable to any element, but Safari5 and Chrome13 still can't do that
                if (item.accesskey) {
                    var aks = splitAccesskey(item.accesskey);
                    for (var i=0, ak; ak = aks[i]; i++) {
                        if (!root.accesskeys[ak]) {
                            root.accesskeys[ak] = item;
                            item._name = item.name.replace(new RegExp('(' + ak + ')', 'i'), '<span class="context-menu-accesskey">$1</span>');
                            break;
                        }
                    }
                }
                
                if (typeof item == "string") {
                    $t.addClass('context-menu-separator not-selectable');
                } else if (item.type && types[item.type]) {
                    // run custom type handler
                    types[item.type].call($t, item, opt, root);
                    // register commands
                    $.each([opt, root], function(i,k){
                        k.commands[key] = item;
                        if ($.isFunction(item.callback)) {
                            k.callbacks[key] = item.callback;
                        }
                    });
                } else {
                    // add label for input
                    if (item.type == 'html') {
                        $t.addClass('context-menu-html not-selectable');
                    } else if (item.type) {
                        $label = $('<label></label>').appendTo($t);
                        $('<span></span>').html(item._name || item.name).appendTo($label);
                        $t.addClass('context-menu-input');
                        opt.hasTypes = true;
                        $.each([opt, root], function(i,k){
                            k.commands[key] = item;
                            k.inputs[key] = item;
                        });
                    } else if (item.items) {
                        item.type = 'sub';
                    }
                
                    switch (item.type) {
                        case 'text':
                            $input = $('<input type="text" value="1" name="context-menu-input-'+ key +'" value="">')
                                .val(item.value || "").appendTo($label);
                            break;
                    
                        case 'textarea':
                            $input = $('<textarea name="context-menu-input-'+ key +'"></textarea>')
                                .val(item.value || "").appendTo($label);

                            if (item.height) {
                                $input.height(item.height);
                            }
                            break;

                        case 'checkbox':
                            $input = $('<input type="checkbox" value="1" name="context-menu-input-'+ key +'" value="">')
                                .val(item.value || "").prop("checked", !!item.selected).prependTo($label);
                            break;

                        case 'radio':
                            $input = $('<input type="radio" value="1" name="context-menu-input-'+ item.radio +'" value="">')
                                .val(item.value || "").prop("checked", !!item.selected).prependTo($label);
                            break;
                    
                        case 'select':
                            $input = $('<select name="context-menu-input-'+ key +'">').appendTo($label);
                            if (item.options) {
                                $.each(item.options, function(value, text) {
                                    $('<option></option>').val(value).text(text).appendTo($input);
                                });
                                $input.val(item.selected);
                            }
                            break;
                        
                        case 'sub':
                            $('<span></span>').html(item._name || item.name).appendTo($t);
                            item.appendTo = item.$node;
                            op.create(item, root);
                            $t.data('contextMenu', item).addClass('context-menu-submenu');
                            item.callback = null;
                            break;
                        
                        case 'html':
                            $(item.html).appendTo($t);
                            break;
                        
                        default:
                            $.each([opt, root], function(i,k){
                                k.commands[key] = item;
                                if ($.isFunction(item.callback)) {
                                    k.callbacks[key] = item.callback;
                                }
                            });
                            
                            $('<span></span>').html(item._name || item.name || "").appendTo($t);
                            break;
                    }
                    
                    // disable key listener in <input>
                    if (item.type && item.type != 'sub' && item.type != 'html') {
                        $input
                            .on('focus', handle.focusInput)
                            .on('blur', handle.blurInput);
                        
                        if (item.events) {
                            $input.on(item.events, opt);
                        }
                    }
                
                    // add icons
                    if (item.icon) {
                        $t.addClass("icon icon-" + item.icon);
                    }
                }
                
                // cache contained elements
                item.$input = $input;
                item.$label = $label;

                // attach item to menu
                $t.appendTo(opt.$menu);
                
                // Disable text selection
                if (!opt.hasTypes && $.support.eventSelectstart) {
                    // browsers support user-select: none, 
                    // IE has a special event for text-selection
                    // browsers supporting neither will not be preventing text-selection
                    $t.on('selectstart.disableTextSelect', handle.abortevent);
                }
            });
            // attach contextMenu to <body> (to bypass any possible overflow:hidden issues on parents of the trigger element)
            if (!opt.$node) {
                opt.$menu.css('display', 'none').addClass('context-menu-root');
            }
            opt.$menu.appendTo(opt.appendTo || document.body);
        },
        update: function(opt, root) {
            var $this = this;
            if (root === undefined) {
                root = opt;
                // determine widths of submenus, as CSS won't grow them automatically
                // position:absolute > position:absolute; min-width:100; max-width:200; results in width: 100;
                // kinda sucks hard...
                opt.$menu.find('ul').andSelf().css({position: 'static', display: 'block'}).each(function(){
                    var $this = $(this);
                    $this.width($this.css('position', 'absolute').width())
                        .css('position', 'static');
                }).css({position: '', display: ''});
            }
            // re-check disabled for each item
            opt.$menu.children().each(function(){
                var $item = $(this),
                    key = $item.data('contextMenuKey'),
                    item = opt.items[key],
                    disabled = ($.isFunction(item.disabled) && item.disabled.call($this, key, root)) || item.disabled === true;

                // dis- / enable item
                $item[disabled ? 'addClass' : 'removeClass']('disabled');
                
                if (item.type) {
                    // dis- / enable input elements
                    $item.find('input, select, textarea').prop('disabled', disabled);
                    
                    // update input states
                    switch (item.type) {
                        case 'text':
                        case 'textarea':
                            item.$input.val(item.value || "");
                            break;
                            
                        case 'checkbox':
                        case 'radio':
                            item.$input.val(item.value || "").prop('checked', !!item.selected);
                            break;
                            
                        case 'select':
                            item.$input.val(item.selected || "");
                            break;
                    }
                }
                
                if (item.$menu) {
                    // update sub-menu
                    op.update.call($this, item, root);
                }
            });
        },
        layer: function(opt, zIndex) {
            // add transparent layer for click area
            // filter and background for Internet Explorer, Issue #23
            var $layer = opt.$layer = $('<div id="context-menu-layer" style="position:fixed; z-index:' + zIndex + '; top:0; left:0; opacity: 0; filter: alpha(opacity=0); background-color: #000;"></div>')
                .css({height: $win.height(), width: $win.width(), display: 'block'})
                .data('contextMenuRoot', opt)
                .insertBefore(this)
                .on('contextmenu', handle.abortevent)
                .on('mousedown', handle.layerClick);
            
            // IE6 doesn't know position:fixed;
            if (!$.support.fixedPosition) {
                $layer.css({
                    'position' : 'absolute',
                    'height' : $(document).height()
                });
            }
            
            return $layer;
        }
    };

// split accesskey according to http://www.whatwg.org/specs/web-apps/current-work/multipage/editing.html#assigned-access-key
function splitAccesskey(val) {
    var t = val.split(/\s+/),
        keys = [];
        
    for (var i=0, k; k = t[i]; i++) {
        k = k[0].toUpperCase(); // first character only
        // theoretically non-accessible characters should be ignored, but different systems, different keyboard layouts, ... screw it.
        // a map to look up already used access keys would be nice
        keys.push(k);
    }
    
    return keys;
}

// handle contextMenu triggers
$.fn.contextMenu = function(operation) {
    if (operation === undefined) {
        this.first().trigger('contextmenu');
    } else if (operation.x && operation.y) {
        this.first().trigger($.Event("contextmenu", {pageX: operation.x, pageY: operation.y}));
    } else if (operation === "hide") {
        var $menu = this.data('contextMenu').$menu;
        $menu && $menu.trigger('contextmenu:hide');
    } else if (operation) {
        this.removeClass('context-menu-disabled');
    } else if (!operation) {
        this.addClass('context-menu-disabled');
    }
    
    return this;
};

// manage contextMenu instances
$.contextMenu = function(operation, options) {
    if (typeof operation != 'string') {
        options = operation;
        operation = 'create';
    }
    
    if (typeof options == 'string') {
        options = {selector: options};
    } else if (options === undefined) {
        options = {};
    }
    
    // merge with default options
    var o = $.extend(true, {}, defaults, options || {}),
        $document = $(document);
    
    switch (operation) {
        case 'create':
            // no selector no joy
            if (!o.selector) {
                throw new Error('No selector specified');
            }
            // make sure internal classes are not bound to
            if (o.selector.match(/.context-menu-(list|item|input)($|\s)/)) {
                throw new Error('Cannot bind to selector "' + o.selector + '" as it contains a reserved className');
            }
            if (!o.build && (!o.items || $.isEmptyObject(o.items))) {
                throw new Error('No Items sepcified');
            }
            counter ++;
            o.ns = '.contextMenu' + counter;
            namespaces[o.selector] = o.ns;
            menus[o.ns] = o;
            
            // default to right click
            if (!o.trigger) {
                o.trigger = 'right';
            }
            
            if (!initialized) {
                // make sure item click is registered first
                $document
                    .on({
                        'contextmenu:hide.contextMenu': handle.hideMenu,
                        'prevcommand.contextMenu': handle.prevItem,
                        'nextcommand.contextMenu': handle.nextItem,
                        'contextmenu.contextMenu': handle.abortevent,
                        'mouseenter.contextMenu': handle.menuMouseenter,
                        'mouseleave.contextMenu': handle.menuMouseleave
                    }, '.context-menu-list')
                    .on('mouseup.contextMenu', '.context-menu-input', handle.inputClick)
                    .on({
                        'mouseup.contextMenu': handle.itemClick,
                        'contextmenu:focus.contextMenu': handle.focusItem,
                        'contextmenu:blur.contextMenu': handle.blurItem,
                        'contextmenu.contextMenu': handle.abortevent,
                        'mouseenter.contextMenu': handle.itemMouseenter,
                        'mouseleave.contextMenu': handle.itemMouseleave
                    }, '.context-menu-item');

                initialized = true;
            }
            
            // engage native contextmenu event
            $document
                .on('contextmenu' + o.ns, o.selector, o, handle.contextmenu);
            
            switch (o.trigger) {
                case 'hover':
                        $document
                            .on('mouseenter' + o.ns, o.selector, o, handle.mouseenter)
                            .on('mouseleave' + o.ns, o.selector, o, handle.mouseleave);                    
                    break;
                    
                case 'left':
                        $document.on('click' + o.ns, o.selector, o, handle.click);
                    break;
                /*
                default:
                    // http://www.quirksmode.org/dom/events/contextmenu.html
                    $document
                        .on('mousedown' + o.ns, o.selector, o, handle.mousedown)
                        .on('mouseup' + o.ns, o.selector, o, handle.mouseup);
                    break;
                */
            }
            
            // create menu
            if (!o.build) {
                op.create(o);
            }
            break;
        
        case 'destroy':
            if (!o.selector) {
                $document.off('.contextMenu .contextMenuAutoHide');
                $.each(namespaces, function(key, value) {
                    $document.off(value);
                });
                
                namespaces = {};
                menus = {};
                counter = 0;
                initialized = false;
                
                $('#context-menu-layer, .context-menu-list').remove();
            } else if (namespaces[o.selector]) {
                var $visibleMenu = $('.context-menu-list').filter(':visible');
                if ($visibleMenu.length && $visibleMenu.data().contextMenuRoot.$trigger.is(o.selector)) {
                    $visibleMenu.trigger('contextmenu:hide', {force: true});
                }
                
                try {
                    if (menus[namespaces[o.selector]].$menu) {
                        menus[namespaces[o.selector]].$menu.remove();
                    }
                    
                    delete menus[namespaces[o.selector]];
                } catch(e) {
                    menus[namespaces[o.selector]] = null;
                }
                
                $document.off(namespaces[o.selector]);
            }
            break;
        
        case 'html5':
            // if <command> or <menuitem> are not handled by the browser,
            // or options was a bool true,
            // initialize $.contextMenu for them
            if ((!$.support.htmlCommand && !$.support.htmlMenuitem) || (typeof options == "boolean" && options)) {
                $('menu[type="context"]').each(function() {
                    if (this.id) {
                        $.contextMenu({
                            selector: '[contextmenu=' + this.id +']',
                            items: $.contextMenu.fromMenu(this)
                        });
                    }
                }).css('display', 'none');
            }
            break;
        
        default:
            throw new Error('Unknown operation "' + operation + '"');
    }
    
    return this;
};

// import values into <input> commands
$.contextMenu.setInputValues = function(opt, data) {
    if (data === undefined) {
        data = {};
    }
    
    $.each(opt.inputs, function(key, item) {
        switch (item.type) {
            case 'text':
            case 'textarea':
                item.value = data[key] || "";
                break;

            case 'checkbox':
                item.selected = data[key] ? true : false;
                break;
                
            case 'radio':
                item.selected = (data[item.radio] || "") == item.value ? true : false;
                break;
            
            case 'select':
                item.selected = data[key] || "";
                break;
        }
    });
};

// export values from <input> commands
$.contextMenu.getInputValues = function(opt, data) {
    if (data === undefined) {
        data = {};
    }
    
    $.each(opt.inputs, function(key, item) {
        switch (item.type) {
            case 'text':
            case 'textarea':
            case 'select':
                data[key] = item.$input.val();
                break;

            case 'checkbox':
                data[key] = item.$input.prop('checked');
                break;
                
            case 'radio':
                if (item.$input.prop('checked')) {
                    data[item.radio] = item.value;
                }
                break;
        }
    });
    
    return data;
};

// find <label for="xyz">
function inputLabel(node) {
    return (node.id && $('label[for="'+ node.id +'"]').val()) || node.name;
}

// convert <menu> to items object
function menuChildren(items, $children, counter) {
    if (!counter) {
        counter = 0;
    }
    
    $children.each(function() {
        var $node = $(this),
            node = this,
            nodeName = this.nodeName.toLowerCase(),
            label,
            item;
        
        // extract <label><input>
        if (nodeName == 'label' && $node.find('input, textarea, select').length) {
            label = $node.text();
            $node = $node.children().first();
            node = $node.get(0);
            nodeName = node.nodeName.toLowerCase();
        }
        
        /*
         * <menu> accepts flow-content as children. that means <embed>, <canvas> and such are valid menu items.
         * Not being the sadistic kind, $.contextMenu only accepts:
         * <command>, <menuitem>, <hr>, <span>, <p> <input [text, radio, checkbox]>, <textarea>, <select> and of course <menu>.
         * Everything else will be imported as an html node, which is not interfaced with contextMenu.
         */
        
        // http://www.whatwg.org/specs/web-apps/current-work/multipage/commands.html#concept-command
        switch (nodeName) {
            // http://www.whatwg.org/specs/web-apps/current-work/multipage/interactive-elements.html#the-menu-element
            case 'menu':
                item = {name: $node.attr('label'), items: {}};
                counter = menuChildren(item.items, $node.children(), counter);
                break;
            
            // http://www.whatwg.org/specs/web-apps/current-work/multipage/commands.html#using-the-a-element-to-define-a-command
            case 'a':
            // http://www.whatwg.org/specs/web-apps/current-work/multipage/commands.html#using-the-button-element-to-define-a-command
            case 'button':
                item = {
                    name: $node.text(),
                    disabled: !!$node.attr('disabled'),
                    callback: (function(){ return function(){ $node.click(); }; })()
                };
                break;
            
            // http://www.whatwg.org/specs/web-apps/current-work/multipage/commands.html#using-the-command-element-to-define-a-command

            case 'menuitem':
            case 'command':
                switch ($node.attr('type')) {
                    case undefined:
                    case 'command':
                    case 'menuitem':
                        item = {
                            name: $node.attr('label'),
                            disabled: !!$node.attr('disabled'),
                            callback: (function(){ return function(){ $node.click(); }; })()
                        };
                        break;
                        
                    case 'checkbox':
                        item = {
                            type: 'checkbox',
                            disabled: !!$node.attr('disabled'),
                            name: $node.attr('label'),
                            selected: !!$node.attr('checked')
                        };
                        break;
                        
                    case 'radio':
                        item = {
                            type: 'radio',
                            disabled: !!$node.attr('disabled'),
                            name: $node.attr('label'),
                            radio: $node.attr('radiogroup'),
                            value: $node.attr('id'),
                            selected: !!$node.attr('checked')
                        };
                        break;
                        
                    default:
                        item = undefined;
                }
                break;
 
            case 'hr':
                item = '-------';
                break;
                
            case 'input':
                switch ($node.attr('type')) {
                    case 'text':
                        item = {
                            type: 'text',
                            name: label || inputLabel(node),
                            disabled: !!$node.attr('disabled'),
                            value: $node.val()
                        };
                        break;
                        
                    case 'checkbox':
                        item = {
                            type: 'checkbox',
                            name: label || inputLabel(node),
                            disabled: !!$node.attr('disabled'),
                            selected: !!$node.attr('checked')
                        };
                        break;
                        
                    case 'radio':
                        item = {
                            type: 'radio',
                            name: label || inputLabel(node),
                            disabled: !!$node.attr('disabled'),
                            radio: !!$node.attr('name'),
                            value: $node.val(),
                            selected: !!$node.attr('checked')
                        };
                        break;
                    
                    default:
                        item = undefined;
                        break;
                }
                break;
                
            case 'select':
                item = {
                    type: 'select',
                    name: label || inputLabel(node),
                    disabled: !!$node.attr('disabled'),
                    selected: $node.val(),
                    options: {}
                };
                $node.children().each(function(){
                    item.options[this.value] = $(this).text();
                });
                break;
                
            case 'textarea':
                item = {
                    type: 'textarea',
                    name: label || inputLabel(node),
                    disabled: !!$node.attr('disabled'),
                    value: $node.val()
                };
                break;
            
            case 'label':
                break;
            
            default:
                item = {type: 'html', html: $node.clone(true)};
                break;
        }
        
        if (item) {
            counter++;
            items['key' + counter] = item;
        }
    });
    
    return counter;
}

// convert html5 menu
$.contextMenu.fromMenu = function(element) {
    var $this = $(element),
        items = {};
        
    menuChildren(items, $this.children());
    
    return items;
};

// make defaults accessible
$.contextMenu.defaults = defaults;
$.contextMenu.types = types;

})(jQuery);
