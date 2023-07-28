import Vue from 'vue';
import FilepathForm from './components/filepath_form.vue';

const getPopoverData = (el) => ({
  trackLabel: el.dataset.trackLabel,
  dismissKey: el.dataset.dismissKey,
  mergeRequestPath: el.dataset.mergeRequestPath,
  humanAccess: el.dataset.humanAccess,
});

const getInputOptions = (el) => {
  const { testid, qa_selector: qaSelector, ...options } = JSON.parse(el.dataset.inputOptions);
  return {
    ...options,
    'data-testid': testid,
  };
};

export default ({ onTemplateSelected }) => {
  const el = document.getElementById('js-template-selectors-menu');

  const suggestCiYmlEl = document.querySelector('.js-suggest-gitlab-ci-yml');
  const suggestCiYmlData = suggestCiYmlEl ? getPopoverData(suggestCiYmlEl) : undefined;

  return new Vue({
    el,
    render(h) {
      return h(FilepathForm, {
        props: {
          suggestCiYmlData,
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
