import initProjectVisibilitySelector from '../../../project_visibility';
import initProjectNew from '../../../projects/project_new';
import { __ } from '~/locale';
import { deprecatedCreateFlash as createFlash } from '~/flash';

document.addEventListener('DOMContentLoaded', () => {
  initProjectVisibilitySelector();
  initProjectNew.bindEvents();

  import(
    /* webpackChunkName: 'experiment_new_project_creation' */ '../../../projects/experiment_new_project_creation'
  )
    .then(m => {
      const el = document.querySelector('.js-experiment-new-project-creation');

      if (!el) {
        return;
      }

      const config = {
        hasErrors: 'hasErrors' in el.dataset,
        isCiCdAvailable: 'isCiCdAvailable' in el.dataset,
      };
      m.default(el, config);
    })
    .catch(() => {
      createFlash(__('An error occurred while loading project creation UI'));
    });
});
