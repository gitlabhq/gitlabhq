import Vue from 'vue';
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

  return new Vue({
    el,
    render(h) {
      return h(FilepathForm, {
        props: {
          inputOptions: getInputOptions(el),
          templates: JSON.parse(el.dataset.templates),
          initialTemplate: el.dataset.selected,
        },
        on: {
          'template-selected': onTemplateSelected,
        },
      });
    },
  });
};
