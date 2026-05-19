import { createAlert } from '~/alert';
import axios from './lib/utils/axios_utils';
import { n__, s__ } from './locale';

export function getHeaderText(childElementCount, mergeRequestCount) {
  if (childElementCount === 0) {
    return `${mergeRequestCount} ${n__('merge request', 'merge requests', mergeRequestCount)}`;
  }
  return ',';
}

export function createHeader(childElementCount, mergeRequestCount) {
  const header = document.createElement('span');
  header.className = 'gl-mr-2';
  header.textContent = getHeaderText(childElementCount, mergeRequestCount);
  return header;
}

export function createLink(mergeRequest) {
  const link = document.createElement('a');
  link.className = 'gl-mr-2';
  link.href = mergeRequest.path;
  link.textContent = `!${mergeRequest.iid}`;
  return link;
}

export function createTitle(mergeRequest) {
  const title = document.createElement('span');
  title.textContent = mergeRequest.title;
  return title;
}

export function createItem(mergeRequest) {
  const item = document.createElement('span');
  item.append(createLink(mergeRequest), createTitle(mergeRequest));
  return item;
}

export function createContent(mergeRequests) {
  const content = document.createElement('span');

  if (mergeRequests.length === 0) {
    content.textContent = s__('Commits|No related merge requests found');
  } else {
    mergeRequests.forEach((mergeRequest) => {
      content.append(
        createHeader(content.childElementCount, mergeRequests.length),
        createItem(mergeRequest),
      );
    });
  }

  return content;
}

export function fetchCommitMergeRequests() {
  const container = document.getElementById('js-commit-merge-requests');

  if (!container) return;

  axios
    .get(container.dataset.projectCommitPath)
    .then((response) => {
      container.replaceChildren(createContent(response.data));
    })
    .catch(() =>
      createAlert({
        message: s__('Commits|An error occurred while fetching merge requests data.'),
      }),
    );
}
