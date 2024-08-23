import Vue from 'vue';
import Facade from './components/common/facade.vue';

const renderGlqlNode = async (el) => {
  const container = document.createElement('div');
  el.parentNode.replaceChild(container, el);

  return new Vue({
    el: container,
    render: (h) => h(Facade, { props: { query: el.textContent } }),
  });
};

const renderGlqlNodes = (els) => {
  return Promise.all([...els].map(renderGlqlNode));
};

export default renderGlqlNodes;
