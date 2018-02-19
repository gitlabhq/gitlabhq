/* global ace */
import GLForm from '~/gl_form';
import ZenMode from '~/zen_mode';

export default () => {
  const editor = ace.edit('editor');

  new GLForm($('.snippet-form'), false); // eslint-disable-line no-new
  new ZenMode(); // eslint-disable-line no-new

  $('.snippet-form-holder form').on('submit', () => {
    $('.snippet-file-content').val(editor.getValue());
  });
};
