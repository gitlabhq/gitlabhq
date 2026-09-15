import Vue from 'vue';
import { __ } from '~/locale';
import PanelWidthResizer from '~/vue_shared/components/panel_width_resizer.vue';

const mountResizer = (targetEl, props) => {
  const mountEl = document.createElement('div');
  targetEl.appendChild(mountEl);

  return new Vue({
    el: mountEl,
    name: 'PanelWidthResizerRoot',
    render(h) {
      return h(PanelWidthResizer, { props: { targetEl, ...props } });
    },
  });
};

/**
 * Makes the static and dynamic content panels drag-resizable, the same way
 * the AI panel is. The AI panel ships its own resizer; the static panel's
 * right edge and the dynamic panel portal's left edge are covered here, so
 * every panel boundary of the paneled layout has a handle.
 */
export default function initPanelResizers() {
  const staticPanel = document.querySelector('.js-static-panel');
  const dynamicPanelPortal = document.querySelector('#contextual-panel-portal');

  if (dynamicPanelPortal) {
    mountResizer(dynamicPanelPortal, { side: 'left', resizeLabel: __('Resize dynamic panel') });
  }

  if (staticPanel) {
    // While the dynamic panel is open it owns the shared edge with its own
    // handle, so the static panel's handle hides.
    mountResizer(staticPanel, {
      side: 'right',
      hideWhenVisibleEl: dynamicPanelPortal,
      resizeLabel: __('Resize static panel'),
    });
  }
}
