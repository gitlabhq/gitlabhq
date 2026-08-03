import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import App from './components/app.vue';
import createStore from './store';

export default (initialData) => {
  const el = document.getElementById('js-code-navigation');

  if (!el) return null;

  const store = createStore();

  store.dispatch('setInitialData', initialData);

  return initVueApp({ el, store, component: App });
};
