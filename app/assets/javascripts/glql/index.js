import Vue from 'vue';
import { simpleHash } from '../lib/utils/text_utility';
import Facade from './components/common/facade.vue';

const renderGlqlNode = (el) => {
  const container = document.createElement('div');
  const pre = el.closest('pre');

  // When wrapped in a js-markdown-code block we want to hide the copy-code button
  const wrapper = pre.closest('.js-markdown-code') || pre;

  if (!wrapper.parentNode) return null;

  wrapper.parentNode.replaceChild(container, wrapper);

  return new Vue({
    el: container,
    render: (h) =>
      h(Facade, {
        props: {
          queryKey: simpleHash(pre.textContent + pre.dataset.sourcepos),
          queryYaml: pre.textContent,
        },
      }),
  });
};

const renderGlqlNodes = (els) => {
  return Promise.all([...els].map(renderGlqlNode));
};

export default renderGlqlNodes;
