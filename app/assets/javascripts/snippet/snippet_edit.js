import $ from 'jquery';
import initSnippet from '~/snippet/snippet_bundle';
import ZenMode from '~/zen_mode';
import GLForm from '~/gl_form';

document.addEventListener('DOMContentLoaded', () => {
  const form = document.querySelector('.snippet-form');
  const personalSnippetOptions = {
    members: false,
    issues: false,
    mergeRequests: false,
    epics: false,
    milestones: false,
    labels: false,
    snippets: false,
  };
  const projectSnippetOptions = {};

  const options =
    form.dataset.snippetType === 'project' ? projectSnippetOptions : personalSnippetOptions;

  initSnippet();
  new ZenMode(); // eslint-disable-line no-new
  new GLForm($(form), options); // eslint-disable-line no-new
});
