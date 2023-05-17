import * as Sentry from '@sentry/browser';
import { HEADER_INIT_EVENTS } from './constants';

async function eventHandler(callback = () => {}) {
  const { initHeaderSearchApp } = await import(
    /* webpackChunkName: 'globalSearch' */ '~/header_search'
  ).catch((error) => Sentry.captureException(error));

  // In case the user started searching before we bootstrapped,
  // let's pass the search along.
  const initialSearchValue = this.searchInputBox.value;
  initHeaderSearchApp(initialSearchValue);

  // this is new #search input element. We need to re-find it.
  // And re-focus in it.
  document.querySelector('#search').focus();
  callback();
}

function cleanEventListeners() {
  HEADER_INIT_EVENTS.forEach((eventType) => {
    document.querySelector('#search').removeEventListener(eventType, eventHandler);
  });
}

function initHeaderSearch() {
  const searchInputBox = document.querySelector('#search');

  HEADER_INIT_EVENTS.forEach((eventType) => {
    searchInputBox?.addEventListener(
      eventType,
      eventHandler.bind({ searchInputBox }, cleanEventListeners),
      { once: true },
    );
  });
}

export default initHeaderSearch;
export { eventHandler, cleanEventListeners };
