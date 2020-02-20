/* global ace */

import $ from 'jquery';
import setupCollapsibleInputs from './collapsible_input';

export default () => {
  const editor = ace.edit('editor');

  $('.snippet-form-holder form').on('submit', () => {
    $('.snippet-file-content').val(editor.getValue());
  });

  setupCollapsibleInputs();
};
