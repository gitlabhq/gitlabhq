import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import HeaderMetadata from './components/header_metadata.vue';

export function mountHeaderMetadata(store) {
  const el = document.querySelector('.js-header-metadata-root');

  if (!el) {
    return null;
  }

  return new Vue({
    el,
    name: 'HeaderMetadataRoot',
    store,
    provide: { hidden: parseBoolean(el.dataset.hidden) },
    render: (createElement) => createElement(HeaderMetadata),
  });
}
