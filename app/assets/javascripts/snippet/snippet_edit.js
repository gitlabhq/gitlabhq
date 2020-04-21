import $ from 'jquery';
import initSnippet from '~/snippet/snippet_bundle';
import ZenMode from '~/zen_mode';
import GLForm from '~/gl_form';
import { SnippetEditInit } from '~/snippets';

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
    form.dataset.snippetType === 'project' || form.dataset.projectPath
      ? projectSnippetOptions
      : personalSnippetOptions;

  if (gon?.features?.snippetsEditVue) {
    SnippetEditInit();
  } else {
    initSnippet();
    new GLForm($(form), options); // eslint-disable-line no-new
  }
  new ZenMode(); // eslint-disable-line no-new
});
