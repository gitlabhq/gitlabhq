import initProjectVisibilitySelector from '../../../project_visibility';
import initProjectNew from '../../../projects/project_new';
import { __ } from '~/locale';
import createFlash from '~/flash';
import Tracking from '~/tracking';

document.addEventListener('DOMContentLoaded', () => {
  initProjectVisibilitySelector();
  initProjectNew.bindEvents();

  const { category, property } = gon.tracking_data ?? { category: 'projects:new' };
  const hasNewCreateProjectUi = 'newCreateProjectUi' in gon?.features;

  if (!hasNewCreateProjectUi) {
    // Setting additional tracking for HAML template

    Array.from(
      document.querySelectorAll('.project-edit-container [data-experiment-track-label]'),
    ).forEach(node =>
      node.addEventListener('click', event => {
        const { experimentTrackLabel: label } = event.currentTarget.dataset;
        Tracking.event(category, 'click_tab', { property, label });
      }),
    );
  } else {
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
  }
});
