import Vue from 'vue';
import TodosApp from './components/todos_app.vue';

export default () => {
  const el = document.getElementById('js-todos-app-root');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(createElement) {
      return createElement(TodosApp);
    },
  });
};
