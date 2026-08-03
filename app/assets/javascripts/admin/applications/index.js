import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DeleteApplication from './components/delete_application.vue';

export default () => {
  const el = document.querySelector('.js-application-delete-modal');

  if (!el) return false;

  return initVueApp({ el, name: 'DeleteApplicationRoot', component: DeleteApplication });
};
