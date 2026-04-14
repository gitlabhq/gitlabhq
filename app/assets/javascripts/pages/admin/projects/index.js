import Vue from 'vue';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import { initJHTransitionBanner } from '~/admin/banners/jh_transition_banner';
import NamespaceSelect from './components/namespace_select.vue';

function mountNamespaceSelect() {
  const el = document.querySelector('.js-namespace-select');
  if (!el) {
    return false;
  }

  const { fieldName, toggleTextPlaceholder, selectedId, selectedText, updateLocation } = el.dataset;

  return new Vue({
    el,
    name: 'NamespaceSelectRoot',
    render(createComponent) {
      return createComponent(NamespaceSelect, {
        props: {
          fieldName,
          toggleTextPlaceholder,
          origSelectedId: selectedId,
          origSelectedText: selectedText,
        },
        on: {
          setNamespace(newNamespace) {
            if (fieldName && updateLocation) {
              window.location = mergeUrlParams({ [fieldName]: newNamespace }, window.location.href);
            }
          },
        },
      });
    },
  });
}

mountNamespaceSelect();
initJHTransitionBanner();
