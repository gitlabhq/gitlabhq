import CILintEditor from '../ci_lint_editor';
import initCILint from '~/ci_lint/index';

document.addEventListener('DOMContentLoaded', () => {
  if (gon?.features?.ciLintVue) {
    initCILint();
  } else {
    // eslint-disable-next-line no-new
    new CILintEditor();
  }
});
