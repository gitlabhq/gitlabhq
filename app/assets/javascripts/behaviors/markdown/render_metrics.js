import Vue from 'vue';
import { createStore } from '~/monitoring/stores/embed_group/';

// TODO: Handle copy-pasting - https://gitlab.com/gitlab-org/gitlab-foss/issues/64369.
export default function renderMetrics(elements) {
  if (!elements.length) {
    return Promise.resolve();
  }

  const wrapperList = [];

  elements.forEach(element => {
    let wrapper;
    const { previousElementSibling } = element;
    const isFirstElementInGroup = !previousElementSibling?.urls;

    if (isFirstElementInGroup) {
      wrapper = document.createElement('div');
      wrapper.urls = [element.dataset.dashboardUrl];
      element.parentNode.insertBefore(wrapper, element);
      wrapperList.push(wrapper);
    } else {
      wrapper = previousElementSibling;
      wrapper.urls.push(element.dataset.dashboardUrl);
    }

    // Clean up processed element
    element.parentNode.removeChild(element);
  });

  return import(
    /* webpackChunkName: 'gfm_metrics' */ '~/monitoring/components/embeds/embed_group.vue'
  ).then(({ default: EmbedGroup }) => {
    const EmbedGroupComponent = Vue.extend(EmbedGroup);

    wrapperList.forEach(wrapper => {
      // eslint-disable-next-line no-new
      new EmbedGroupComponent({
        el: wrapper,
        store: createStore(),
        propsData: {
          urls: wrapper.urls,
        },
      });
    });
  });
}
