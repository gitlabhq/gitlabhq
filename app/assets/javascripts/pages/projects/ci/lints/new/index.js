import createFlash from '~/flash';
import { __ } from '~/locale';

const ERROR = __('An error occurred while rendering the linter');

document.addEventListener('DOMContentLoaded', () => {
  if (gon?.features?.ciLintVue) {
    import(/* webpackChunkName: 'ciLintIndex' */ '~/ci_lint/index')
      .then(module => module.default())
      .catch(() => createFlash({ message: ERROR }));
  } else {
    import(/* webpackChunkName: 'ciLintEditor' */ '../ci_lint_editor')
      // eslint-disable-next-line new-cap
      .then(module => new module.default())
      .catch(() => createFlash({ message: ERROR }));
  }
});
