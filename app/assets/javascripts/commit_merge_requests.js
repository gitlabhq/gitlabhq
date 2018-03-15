/* global Flash */

import $ from 'jquery';
import axios from './lib/utils/axios_utils';
import { n__, s__ } from './locale';

export function getHeaderText(childElementCount, mergeRequestCount) {
  if (childElementCount === 0) {
    return `${mergeRequestCount} ${n__('merge request', 'merge requests', mergeRequestCount)}`;
  }
  return ',';
}

export function createHeader(childElementCount, mergeRequestCount) {
  const headerText = getHeaderText(childElementCount, mergeRequestCount);

  return $('<span />', {
    class: 'append-right-5',
    text: headerText,
  });
}

export function createLink(mergeRequest) {
  return $('<a />', {
    class: 'append-right-5',
    href: mergeRequest.path,
    text: `!${mergeRequest.iid}`,
  });
}

export function createTitle(mergeRequest) {
  return $('<span />', {
    text: mergeRequest.title,
  });
}

export function createItem(mergeRequest) {
  const $item = $('<span />');
  const $link = createLink(mergeRequest);
  const $title = createTitle(mergeRequest);
  $item.append($link);
  $item.append($title);

  return $item;
}

export function createContent(mergeRequests) {
  const $content = $('<span />');

  if (mergeRequests.length === 0) {
    $content.text(s__('Commits|No related merge requests found'));
  } else {
    mergeRequests.forEach((mergeRequest) => {
      const $header = createHeader($content.children().length, mergeRequests.length);
      const $item = createItem(mergeRequest);
      $content.append($header);
      $content.append($item);
    });
  }

  return $content;
}

export function fetchCommitMergeRequests() {
  const $container = $('.merge-requests');

  axios.get($container.data('projectCommitPath'))
    .then((response) => {
      const $content = createContent(response.data);

      $container.html($content);
    })
    .catch(() => Flash(s__('Commits|An error occurred while fetching merge requests data.')));
}
