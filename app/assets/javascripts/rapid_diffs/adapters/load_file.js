import axios from '~/lib/utils/axios_utils';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { pinia } from '~/pinia/instance';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';

function htmlToElement(html) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(html, 'text/html');
  return doc.body.firstChild;
}

async function loadFile(params = {}) {
  const { parallelView, showWhitespace } = useDiffsView(pinia);
  const url = new URL(this.appData.diffFileEndpoint, window.location.origin);
  const { oldPath, newPath } = this.data;
  if (oldPath) url.searchParams.set('old_path', oldPath);
  if (newPath) url.searchParams.set('new_path', newPath);
  url.searchParams.set('ignore_whitespace_changes', !showWhitespace);
  if (parallelView) url.searchParams.set('view', 'parallel');
  Object.keys(params).forEach((key) => {
    url.searchParams.set(key, params[key]);
  });
  const response = await axios.get(url.toString());
  const node = htmlToElement(response.data);
  this.replaceWith(node);
}

async function loadWithDisabledButton(button, params) {
  try {
    button.setAttribute('disabled', true);
    await loadFile.call(this, params);
  } catch (error) {
    createAlert({
      message: s__('RapidDiffs|Failed to load changes, please try again.'),
      parent: this.diffElement,
      error,
    });
    button.removeAttribute('disabled');
  }
}

export const loadFileAdapter = {
  clicks: {
    showChanges(event, button) {
      loadWithDisabledButton.call(this, button);
    },
    showFullFile(event, button) {
      loadWithDisabledButton.call(this, button, {
        full: !button.dataset.full,
      });
    },
    toggleRichView(event, button) {
      loadWithDisabledButton.call(this, button, {
        plain_view: JSON.parse(button.dataset.rendered),
      });
    },
  },
};
