import { memoize } from 'lodash';
import Vue from 'vue';
import { __ } from '~/locale';
import { createAlert } from '~/alert';
import { parseBoolean } from '~/lib/utils/common_utils';

// Async import component since we might not need it...
const JSONTable = memoize(
  () => import(/* webpackChunkName: 'gfm_json_table' */ '../components/json_table.vue'),
);

const mountParseError = (element) => {
  // Let the error container be a sibling to the element.
  // Otherwise, dismissing the alert causes the copy button to be misplaced.
  const container = document.createElement('div');
  element.insertAdjacentElement('beforebegin', container);

  // We need to create a child element with a known selector for `createAlert`
  const el = document.createElement('div');
  el.classList.add('js-json-table-error');

  container.insertAdjacentElement('afterbegin', el);

  return createAlert({
    message: __('Unable to parse JSON'),
    variant: 'warning',
    parent: container,
    containerSelector: '.js-json-table-error',
  });
};

const mountJSONTableVueComponent = (userData, element) => {
  const { fields = [], items = [], filter, caption, isHtmlSafe } = userData;
  const container = document.createElement('div');

  element.classList.add('js-json-table');
  element.replaceChildren(container);

  const props = {
    fields,
    items,
    hasFilter: filter,
    isHtmlSafe,
  };

  if (caption) {
    props.caption = caption;
  }

  return new Vue({
    el: container,
    render(h) {
      return h(JSONTable, { props });
    },
  });
};

const renderTable = (element) => {
  // Avoid rendering multiple times
  if (!element || element.classList.contains('js-json-table')) {
    return;
  }

  try {
    mountJSONTableVueComponent(JSON.parse(element.textContent), element);
  } catch (e) {
    mountParseError(element);
  }
};

const renderTableHTML = (element) => {
  const parent = element.parentElement;

  // Avoid rendering multiple times
  if (!parent || parent.classList.contains('js-json-table')) {
    return;
  }

  try {
    // Extract data from rendered HTML table
    const fields = JSON.parse(element.dataset.tableFields);
    const filter = parseBoolean(element.dataset.tableFilter);
    const markdown = parseBoolean(element.dataset.tableMarkdown);

    // The caption was processed with markdown, so it's wrapped in a <p>.
    // We want that removed so it will fit semantically within a <small>.
    const captionNode = element.querySelector('caption p');
    const caption = captionNode ? captionNode.innerHTML : null;

    const items = Array.from(element.querySelectorAll('tbody tr').values()).map((row) =>
      fields.reduce(
        (item, field, index) => ({
          ...item,
          [field.key]: row.querySelectorAll('td').item(index).innerHTML,
        }),
        {},
      ),
    );

    mountJSONTableVueComponent({ fields, filter, caption, items, isHtmlSafe: markdown }, parent);
  } catch (e) {
    mountParseError(parent);
  }
};

export const renderJSONTable = (elements) => {
  elements.forEach(renderTable);
};

export const renderJSONTableHTML = (elements) => {
  elements.forEach(renderTableHTML);
};
