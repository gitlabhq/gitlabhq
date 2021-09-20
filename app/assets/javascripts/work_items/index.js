import Vue from 'vue';
import App from './components/app.vue';

export const initWorkItemsRoot = () => {
  const el = document.querySelector('#js-work-items');

  return new Vue({
    el,
    render(createElement) {
      return createElement(App);
    },
  });
};
