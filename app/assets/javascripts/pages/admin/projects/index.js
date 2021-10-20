import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';
import ProjectsList from '~/projects_list';
import NamespaceSelect from './components/namespace_select.vue';

new ProjectsList(); // eslint-disable-line no-new

function mountNamespaceSelect() {
  const el = document.querySelector('.js-namespace-select');
  if (!el) {
    return false;
  }

  const { showAny, fieldName, placeholder, updateLocation } = el.dataset;

  return new Vue({
    el,
    render(createComponent) {
      return createComponent(NamespaceSelect, {
        props: {
          showAny: parseBoolean(showAny),
          fieldName,
          placeholder,
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
