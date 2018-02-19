/* global ace */
import initForm from '~/pages/projects/init_form';

document.addEventListener('DOMContentLoaded', () => {
  const editor = ace.edit('editor');

  initForm($('.snippet-form'));

  $('.snippet-form-holder form').on('submit', () => {
    $('.snippet-file-content').val(editor.getValue());
  });
});
