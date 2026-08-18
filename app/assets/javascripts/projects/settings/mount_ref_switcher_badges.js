import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { visitUrl } from '~/lib/utils/url_utility';
import { generateRefDestinationPath } from './utils';

export default function initRefSwitcherBadges() {
  const refSwitcherElements = document.getElementsByClassName('js-ref-switcher-badge');

  if (refSwitcherElements.length === 0) return false;

  return Array.from(refSwitcherElements).forEach((element) => {
    const { projectId, ref } = element.dataset;

    return initVueApp({
      el: element,
      name: 'RefSelectorRoot',
      component: RefSelector,
      props: {
        projectId,
        value: ref,
      },
      events: {
        input(selectedRef) {
          visitUrl(generateRefDestinationPath(selectedRef));
        },
      },
    });
  });
}
