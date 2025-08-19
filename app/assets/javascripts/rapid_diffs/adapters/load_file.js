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

export const loadFileAdapter = {
  clicks: {
    async showChanges(event, button) {
      const { parallelView, showWhitespace } = useDiffsView(pinia);
      const url = new URL(this.appData.diffFileEndpoint, window.location.origin);
      const { old_path: oldPath, new_path: newPath } = JSON.parse(button.dataset.paths);
      if (oldPath) url.searchParams.set('old_path', oldPath);
      if (newPath) url.searchParams.set('new_path', newPath);
      url.searchParams.set('ignore_whitespace_changes', !showWhitespace);
      if (parallelView) url.searchParams.set('view', 'parallel');
      button.setAttribute('disabled', true);
      let response;
      try {
        response = await axios.get(url.toString());
      } catch (error) {
        button.removeAttribute('disabled');
        createAlert({
          message: s__('RapidDiffs|Failed to load changes, please try again.'),
          error,
        });
        return;
      }
      const node = htmlToElement(response.data);
      this.replaceWith(node);
    },
  },
};
