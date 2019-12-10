/* eslint-disable func-names, consistent-return, no-return-assign */

import $ from 'jquery';
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import sanitize from 'sanitize-html';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';

// highlight text(awefwbwgtc -> <b>a</b>wefw<b>b</b>wgt<b>c</b> )
const highlighter = function(element, text, matches) {
  let j = 0;
  let len = 0;
  let lastIndex = 0;
  let matchedChars = [];
  let matchIndex = matches[j];
  let unmatched = text.substring(lastIndex, matchIndex);
  for (j = 0, len = matches.length; j < len; j += 1) {
    matchIndex = matches[j];
    unmatched = text.substring(lastIndex, matchIndex);
    if (unmatched) {
      if (matchedChars.length) {
        element.append(matchedChars.join('').bold());
      }
      matchedChars = [];
      element.append(document.createTextNode(unmatched));
    }
    matchedChars.push(text[matchIndex]);
    lastIndex = matchIndex + 1;
  }
  if (matchedChars.length) {
    element.append(matchedChars.join('').bold());
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
    this.inputElement = this.element.find('.file-finder-input');
    // init event
    this.initEvent();
    // focus text input box
    this.inputElement.focus();
    // load file list
    this.load(this.options.url);
  }

  initEvent() {
    this.inputElement.off('keyup');
    this.inputElement.on(
      'keyup',
      (function(_this) {
        return function(event) {
          const target = $(event.target);
          const value = target.val();
          const ref = target.data('oldValue');
          const oldValue = ref != null ? ref : '';
          if (value !== oldValue) {
            target.data('oldValue', value);
            _this.findFile();
            return _this.element
              .find('tr.tree-item')
              .eq(0)
              .addClass('selected')
              .focus();
          }
        };
      })(this),
    );
  }

  findFile() {
    const searchText = sanitize(this.inputElement.val());
    const result =
      searchText.length > 0 ? fuzzaldrinPlus.filter(this.filePaths, searchText) : this.filePaths;
    return this.renderList(result, searchText);
    // find file
  }

  // files paths load
  load(url) {
    axios
      .get(url)
      .then(({ data }) => {
        this.element.find('.loading').hide();
        this.filePaths = data;
        this.findFile();
        this.element
          .find('.files-slider tr.tree-item')
          .eq(0)
          .addClass('selected')
          .focus();
      })
      .catch(() => flash(__('An error occurred while loading filenames')));
  }

  // render result
  renderList(filePaths, searchText) {
    let i = 0;
    let len = 0;
    let matches = [];
    const results = [];
    this.element.find('.tree-table > tbody').empty();
    for (i = 0, len = filePaths.length; i < len; i += 1) {
      const filePath = filePaths[i];
      if (i === 20) {
        break;
      }
      if (searchText) {
        matches = fuzzaldrinPlus.match(filePath, searchText);
      }
      const blobItemUrl = `${this.options.blobUrlTemplate}/${encodeURIComponent(filePath)}`;
      const html = ProjectFindFile.makeHtml(filePath, matches, blobItemUrl);
      results.push(this.element.find('.tree-table > tbody').append(html));
    }

    this.element.find('.empty-state').toggleClass('hidden', Boolean(results.length));

    return results;
  }

  // make tbody row html
  static makeHtml(filePath, matches, blobItemUrl) {
    const $tr = $(
      "<tr class='tree-item'><td class='tree-item-file-name link-container'><a><i class='fa fa-file-text-o fa-fw'></i><span class='str-truncated'></span></a></td></tr>",
    );
    if (matches) {
      $tr
        .find('a')
        .replaceWith(highlighter($tr.find('a'), filePath, matches).attr('href', blobItemUrl));
    } else {
      $tr.find('a').attr('href', blobItemUrl);
      $tr.find('.str-truncated').text(filePath);
    }
    return $tr;
  }

  selectRow(type) {
    const rows = this.element.find('.files-slider tr.tree-item');
    let selectedRow = this.element.find('.files-slider tr.tree-item.selected');
    let next = selectedRow.prev();
    if (rows && rows.length > 0) {
      if (selectedRow && selectedRow.length > 0) {
        if (type === 'UP') {
          next = selectedRow.prev();
        } else if (type === 'DOWN') {
          next = selectedRow.next();
        }
        if (next.length > 0) {
          selectedRow.removeClass('selected');
          selectedRow = next;
        }
      } else {
        selectedRow = rows.eq(0);
      }
      return selectedRow.addClass('selected').focus();
    }
  }

  selectRowUp() {
    return this.selectRow('UP');
  }

  selectRowDown() {
    return this.selectRow('DOWN');
  }

  goToTree() {
    return (window.location.href = this.options.treeUrl);
  }

  goToBlob() {
    const $link = this.element.find('.tree-item.selected .tree-item-file-name a');

    if ($link.length) {
      $link.get(0).click();
    }
  }
}
