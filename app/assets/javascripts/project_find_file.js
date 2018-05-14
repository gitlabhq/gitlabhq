/* eslint-disable func-names, space-before-function-paren, no-var, prefer-rest-params, wrap-iife, quotes, consistent-return, one-var, one-var-declaration-per-line, no-cond-assign, max-len, object-shorthand, no-param-reassign, comma-dangle, prefer-template, no-unused-vars, no-return-assign */

import $ from 'jquery';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';

// highlight text(awefwbwgtc -> <b>a</b>wefw<b>b</b>wgt<b>c</b> )
const highlighter = function(element, text, matches) {
  var highlightText, j, lastIndex, len, matchIndex, matchedChars, unmatched;
  lastIndex = 0;
  highlightText = "";
  matchedChars = [];
  for (j = 0, len = matches.length; j < len; j += 1) {
    matchIndex = matches[j];
    unmatched = text.substring(lastIndex, matchIndex);
    if (unmatched) {
      if (matchedChars.length) {
        element.append(matchedChars.join("").bold());
      }
      matchedChars = [];
      element.append(document.createTextNode(unmatched));
    }
    matchedChars.push(text[matchIndex]);
    lastIndex = matchIndex + 1;
  }
  if (matchedChars.length) {
    element.append(matchedChars.join("").bold());
  }
  return element.append(document.createTextNode(text.substring(lastIndex)));
};

export default class ProjectFindFile {
  constructor(element1, options) {
    this.element = element1;
    this.options = options;
    this.goToBlob = this.goToBlob.bind(this);
    this.goToTree = this.goToTree.bind(this);
    this.selectRowDown = this.selectRowDown.bind(this);
    this.selectRowUp = this.selectRowUp.bind(this);
    this.filePaths = {};
    this.inputElement = this.element.find(".file-finder-input");
    // init event
    this.initEvent();
    // focus text input box
    this.inputElement.focus();
    // load file list
    this.load(this.options.url);
  }

  initEvent() {
    this.inputElement.off("keyup");
    this.inputElement.on("keyup", (function(_this) {
      return function(event) {
        var oldValue, ref, target, value;
        target = $(event.target);
        value = target.val();
        oldValue = (ref = target.data("oldValue")) != null ? ref : "";
        if (value !== oldValue) {
          target.data("oldValue", value);
          _this.findFile();
          return _this.element.find("tr.tree-item").eq(0).addClass("selected").focus();
        }
      };
    })(this));
  }

  findFile() {
    var result, searchText;
    searchText = this.inputElement.val();
    result = searchText.length > 0 ? fuzzaldrinPlus.filter(this.filePaths, searchText) : this.filePaths;
    return this.renderList(result, searchText);
  // find file
  }

  // files pathes load
  load(url) {
    axios.get(url)
      .then(({ data }) => {
        this.element.find('.loading').hide();
        this.filePaths = data;
        this.findFile();
        this.element.find('.files-slider tr.tree-item').eq(0).addClass('selected').focus();
      })
      .catch(() => flash(__('An error occurred while loading filenames')));
  }

  // render result
  renderList(filePaths, searchText) {
    var blobItemUrl, filePath, html, i, j, len, matches, results;
    this.element.find(".tree-table > tbody").empty();
    results = [];
    for (i = j = 0, len = filePaths.length; j < len; i = (j += 1)) {
      filePath = filePaths[i];
      if (i === 20) {
        break;
      }
      if (searchText) {
        matches = fuzzaldrinPlus.match(filePath, searchText);
      }
      blobItemUrl = this.options.blobUrlTemplate + "/" + filePath;
      html = ProjectFindFile.makeHtml(filePath, matches, blobItemUrl);
      results.push(this.element.find(".tree-table > tbody").append(html));
    }
    return results;
  }

  // make tbody row html
  static makeHtml(filePath, matches, blobItemUrl) {
    var $tr;
    $tr = $("<tr class='tree-item'><td class='tree-item-file-name link-container'><a><i class='fa fa-file-text-o fa-fw'></i><span class='str-truncated'></span></a></td></tr>");
    if (matches) {
      $tr.find("a").replaceWith(highlighter($tr.find("a"), filePath, matches).attr("href", blobItemUrl));
    } else {
      $tr.find("a").attr("href", blobItemUrl);
      $tr.find(".str-truncated").text(filePath);
    }
    return $tr;
  }

  selectRow(type) {
    var next, rows, selectedRow;
    rows = this.element.find(".files-slider tr.tree-item");
    selectedRow = this.element.find(".files-slider tr.tree-item.selected");
    if (rows && rows.length > 0) {
      if (selectedRow && selectedRow.length > 0) {
        if (type === "UP") {
          next = selectedRow.prev();
        } else if (type === "DOWN") {
          next = selectedRow.next();
        }
        if (next.length > 0) {
          selectedRow.removeClass("selected");
          selectedRow = next;
        }
      } else {
        selectedRow = rows.eq(0);
      }
      return selectedRow.addClass("selected").focus();
    }
  }

  selectRowUp() {
    return this.selectRow("UP");
  }

  selectRowDown() {
    return this.selectRow("DOWN");
  }

  goToTree() {
    return location.href = this.options.treeUrl;
  }

  goToBlob() {
    var $link = this.element.find(".tree-item.selected .tree-item-file-name a");

    if ($link.length) {
      $link.get(0).click();
    }
  }
}
