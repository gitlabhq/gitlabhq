/* eslint-disable func-names, no-return-assign */

import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { createAlert } from '~/alert';
import { sanitize } from '~/lib/dompurify';
import axios from '~/lib/utils/axios_utils';
import { spriteIcon } from '~/lib/utils/common_utils';
import { joinPaths, escapeFileUrl } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

export const appendBoldText = (element, text) => {
  const b = document.createElement('b');
  b.textContent = text;
  element.append(b);
};

// highlight text(awefwbwgtc -> <b>a</b>wefw<b>b</b>wgt<b>c</b> )
export const highlighter = function (element, text, matches) {
  let lastIndex = 0;
  let matchedChars = [];

  for (let j = 0; j < matches.length; j += 1) {
    const matchIndex = matches[j];
    const unmatched = text.substring(lastIndex, matchIndex);
    if (unmatched) {
      if (matchedChars.length) {
        appendBoldText(element, matchedChars.join(''));
      }
      matchedChars = [];
      element.append(document.createTextNode(unmatched));
    }
    matchedChars.push(text[matchIndex]);
    lastIndex = matchIndex + 1;
  }
  if (matchedChars.length) {
    appendBoldText(element, matchedChars.join(''));
  }
  return element.append(document.createTextNode(text.substring(lastIndex)));
};

export default class ProjectFindFile {
  constructor(element, options) {
    this.element = element;
    this.options = options;
    this.goToBlob = this.goToBlob.bind(this);
    this.goToTree = this.goToTree.bind(this);
    this.selectRowDown = this.selectRowDown.bind(this);
    this.selectRowUp = this.selectRowUp.bind(this);
    this.filePaths = {};
    this.inputElement = this.element.querySelector('.file-finder-input');
    this.inputKeyupHandler = null;
    this.initEvent();
    // focus text input box
    this.inputElement.focus();
  }

  initEvent() {
    if (this.inputKeyupHandler) {
      this.inputElement.removeEventListener('keyup', this.inputKeyupHandler);
    }
    this.inputKeyupHandler = ({ target }) => {
      const { value, dataset } = target;
      const oldValue = dataset.oldValue ?? '';
      if (value !== oldValue) {
        dataset.oldValue = value;
        this.findFile();
        const firstRow = this.element.querySelector('tr.tree-item');
        if (firstRow) {
          firstRow.classList.add('selected');
          firstRow.focus();
        }
      }
    };
    this.inputElement.addEventListener('keyup', this.inputKeyupHandler);
  }

  findFile() {
    const searchText = sanitize(this.inputElement.value);
    const result =
      searchText.length > 0 ? fuzzaldrinPlus.filter(this.filePaths, searchText) : this.filePaths;
    return this.renderList(result, searchText);
  }

  // files paths load
  load(url) {
    axios
      .get(url)
      .then(({ data }) => {
        const loadingEl = this.element.querySelector('.loading');
        if (loadingEl) {
          loadingEl.classList.add('!gl-hidden');
        }
        this.filePaths = data;
        this.findFile();
        const firstRow = this.element.querySelector('.files-slider tr.tree-item');
        if (firstRow) {
          firstRow.classList.add('selected');
          firstRow.focus();
        }
      })
      .catch(() =>
        createAlert({
          message: __('An error occurred while loading filenames'),
        }),
      );
  }

  // render result
  renderList(filePaths, searchText) {
    let i = 0;
    let len = 0;
    let matches = [];
    const results = [];
    const tbody = this.element.querySelector('.tree-table > tbody');
    tbody.replaceChildren();
    for (i = 0, len = filePaths.length; i < len; i += 1) {
      const filePath = filePaths[i];
      if (i === 20) {
        break;
      }
      if (searchText) {
        matches = fuzzaldrinPlus.match(filePath, searchText);
      }

      const { blobUrlTemplate, refType } = this.options;
      let blobItemUrl = joinPaths(blobUrlTemplate, escapeFileUrl(filePath));

      if (refType) {
        const blobUrlObject = new URL(blobItemUrl, window.location.origin);
        blobUrlObject.searchParams.append('ref_type', refType);
        blobItemUrl = blobUrlObject.toString();
      }
      const row = ProjectFindFile.makeHtml(filePath, matches, blobItemUrl);
      tbody.appendChild(row);
      results.push(row);
    }

    const emptyState = this.element.querySelector('.empty-state');
    if (emptyState) {
      emptyState.classList.toggle('hidden', Boolean(results.length));
    }

    return results;
  }

  // make tbody row html
  static makeHtml(filePath, matches, blobItemUrl) {
    const tr = document.createElement('tr');
    tr.classList.add('tree-item');

    const td = document.createElement('td');
    td.classList.add('tree-item-file-name', 'link-container');

    const a = document.createElement('a');
    a.innerHTML = sanitize(spriteIcon('doc-text', 's16 vertical-align-middle gl-mr-1'));
    a.href = blobItemUrl;

    const span = document.createElement('span');
    span.classList.add('str-truncated');

    a.appendChild(span);

    if (matches && matches.length) {
      highlighter(a, filePath, matches);
    } else {
      span.textContent = filePath;
    }

    td.appendChild(a);
    tr.appendChild(td);

    return tr;
  }

  selectRow(type) {
    const filesSlider = this.element.querySelector('.files-slider');
    if (!filesSlider) {
      return undefined;
    }
    const [firstRow] = filesSlider.querySelectorAll('tr.tree-item');
    let selectedRow = filesSlider.querySelector('tr.tree-item.selected');
    let next = null;
    if (firstRow) {
      if (selectedRow) {
        const { previousElementSibling, nextElementSibling } = selectedRow;
        if (type === 'UP') {
          next = previousElementSibling;
        } else if (type === 'DOWN') {
          next = nextElementSibling;
        }
        if (next) {
          selectedRow.classList.remove('selected');
          selectedRow = next;
        }
      } else {
        selectedRow = firstRow;
      }
      selectedRow.classList.add('selected');
      selectedRow.focus();
      return selectedRow;
    }
    return undefined;
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
    const link = this.element.querySelector('.tree-item.selected .tree-item-file-name a');

    if (link) {
      link.click();
    }
  }
}
