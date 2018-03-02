/* global ace */

export default () => {
  const editor = ace.edit('editor');

  $('.snippet-form-holder form').on('submit', () => {
    $('.snippet-file-content').val(editor.getValue());
  });
};
