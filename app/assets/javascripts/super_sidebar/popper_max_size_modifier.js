import { detectOverflow } from '@popperjs/core';

/**
 * These modifiers were copied from the community modifier popper-max-size-modifier
 * https://www.npmjs.com/package/popper-max-size-modifier.
 * We are considering upgrading Popper.js to Floating UI, at which point the behavior this
 * introduces will be available out of the box.
 * https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2213
 */

export const maxSize = {
  name: 'maxSize',
  enabled: true,
  phase: 'main',
  requiresIfExists: ['offset', 'preventOverflow', 'flip'],
  fn({ state, name }) {
    const overflow = detectOverflow(state);
    const { x, y } = state.modifiersData.preventOverflow || { x: 0, y: 0 };
    const { width, height } = state.rects.popper;
    const [basePlacement] = state.placement.split('-');

    const widthProp = basePlacement === 'left' ? 'left' : 'right';
    const heightProp = basePlacement === 'top' ? 'top' : 'bottom';

    state.modifiersData[name] = {
      width: width - overflow[widthProp] - x,
      height: height - overflow[heightProp] - y,
    };
  },
};

export const applyMaxSize = {
  name: 'applyMaxSize',
  enabled: true,
  phase: 'write',
  requires: ['maxSize'],
  fn({ state }) {
    // The `maxSize` modifier provides this data
    const { width, height } = state.modifiersData.maxSize;
    state.elements.popper.style.maxWidth = `${width}px`;
    state.elements.popper.style.maxHeight = `${height}px`;
  },
};
