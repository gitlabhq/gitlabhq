import $ from 'jquery';
import initSnippet from '~/snippet/snippet_bundle';
import initForm from '~/pages/projects/init_form';

document.addEventListener('DOMContentLoaded', () => {
  initSnippet();
  initForm($('.snippet-form'));
});
