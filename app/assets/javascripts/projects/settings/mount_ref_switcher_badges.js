import Vue from 'vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { generateRefDestinationPath } from './utils';

export default function initRefSwitcherBadges() {
  const refSwitcherElements = document.getElementsByClassName('js-ref-switcher-badge');

  if (refSwitcherElements.length === 0) return false;

  return Array.from(refSwitcherElements).forEach((element) => {
    const { projectId, ref } = element.dataset;

    return new Vue({
      el: element,
      render(createElement) {
        return createElement(RefSelector, {
          props: {
            projectId,
            value: ref,
          },
          on: {
            input(selectedRef) {
              visitUrl(generateRefDestinationPath(selectedRef));
            },
          },
        });
      },
    });
  });
}
