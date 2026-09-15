import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import CodeDropdown from '~/merge_requests/components/code_dropdown.vue';

export default () => {
  const el = document.querySelector('.js-mr-code-dropdown');

  if (!el) return false;

  return initVueApp({
    el,
    name: 'CodeDropdownRoot',
    component: CodeDropdown,
    props: { ...el.dataset },
  });
};
