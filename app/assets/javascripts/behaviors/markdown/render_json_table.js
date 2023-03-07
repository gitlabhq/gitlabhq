import { memoize } from 'lodash';
import Vue from 'vue';
import { __ } from '~/locale';
import { createAlert } from '~/alert';

// Async import component since we might not need it...
const JSONTable = memoize(() =>
  import(/* webpackChunkName: 'gfm_json_table' */ '../components/json_table.vue'),
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
  const { fields = [], items = [], filter, caption } = userData;

  const container = document.createElement('div');
  element.innerHTML = '';
  element.appendChild(container);

  return new Vue({
    el: container,
    render(h) {
      return h(JSONTable, {
        props: {
          fields,
          items,
          hasFilter: filter,
          caption,
        },
      });
    },
  });
};

const renderTable = (element) => {
  // Avoid rendering multiple times
  if (!element || element.classList.contains('js-json-table')) {
    return;
  }

  element.classList.add('js-json-table');

  try {
    mountJSONTableVueComponent(JSON.parse(element.textContent), element);
  } catch (e) {
    mountParseError(element);
  }
};

export const renderJSONTable = (elements) => {
  elements.forEach(renderTable);
};
