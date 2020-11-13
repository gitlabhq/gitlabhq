import $ from 'jquery';
import initDependencyProxy from '~/dependency_proxy';

document.addEventListener('DOMContentLoaded', () => {
  initDependencyProxy();
});

document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('form.edit_dependency_proxy_group_setting');
  const toggleInput = $('input.js-project-feature-toggle-input');

  if (form && toggleInput) {
    toggleInput.on('trigger-change', () => {
      form.submit();
    });
  }
});
