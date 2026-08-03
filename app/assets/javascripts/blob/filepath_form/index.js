import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import FilepathForm from './components/filepath_form.vue';

const getInputOptions = (el) => {
  const { testid, qa_selector: qaSelector, ...options } = JSON.parse(el.dataset.inputOptions);
  return {
    ...options,
    'data-testid': testid,
  };
};

export default ({ onTemplateSelected }) => {
  const el = document.getElementById('js-template-selectors-menu');

  if (!el) {
    return null;
  }

  return initVueApp({
    el,
    name: 'FilepathFormRoot',
    component: FilepathForm,
    props: {
      inputOptions: getInputOptions(el),
      templates: JSON.parse(el.dataset.templates),
      initialTemplate: el.dataset.selected,
    },
    events: {
      'template-selected': onTemplateSelected,
    },
  });
};
