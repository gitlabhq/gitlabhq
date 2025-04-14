import Vue from 'vue';
import { sha256 } from '../lib/utils/text_utility';
import Facade from './components/common/facade.vue';

const renderGlqlNode = async (el) => {
  const container = document.createElement('div');
  const pre = el.querySelector('pre');
  const queryKey = await sha256(pre.textContent + pre.dataset.sourcepos);

  el.parentNode.replaceChild(container, el);

  return new Vue({
    el: container,
    provide: { queryKey },
    render: (h) =>
      h(Facade, {
        props: { query: pre.textContent },
      }),
  });
};

const renderGlqlNodes = (els) => {
  return Promise.all([...els].map(renderGlqlNode));
};

export default renderGlqlNodes;
