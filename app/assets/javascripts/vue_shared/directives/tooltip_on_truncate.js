import { nextTick } from 'vue';
import { debounce } from 'lodash';
import { GlTooltipDirective, GlResizeObserverDirective } from '@gitlab/ui';
import { hasHorizontalOverflow } from '~/lib/utils/dom_utils';

/**
 * v-tooltip-on-truncate directive
 *
 * v-tooltip-on-truncate is an alternative to the <tooltip-on-truncate>
 * component.
 *
 * Add it to an element which truncates content, so a tooltip with its contents
 * is shown.
 *
 * ```
 * <div v-tooltip-on-truncate style="white-space: nowrap; text-overflow: ellipsis; overflow: hidden;">
 *   A possibly long text...
 * </div>
 * ```
 * By default, it will show the `innerText` of the element, this can be overridden:
 *
 * ```
 * <div
 *   v-tooltip-on-truncate="'An alternative to the long text.'"
 *   style="white-space: nowrap; text-overflow: ellipsis; overflow: hidden"
 * >
 *   A possibly long text...
 * </div>
 * ```
 *
 * Accepts the same modifiers and values as v-tooltip:
 *
 * ```
 * <div
 *   v-tooltip-on-truncate.focus="{ container: 'body', title: 'My tooltip }"
 *   style="white-space: nowrap; text-overflow: ellipsis; overflow: hidden"
 * >
 *   A possibly long text...
 * </div>
 * ```
 */

const RESIZE_DEBOUNCE_WAIT_MS = 300;
const GL_TOOLTIP_ON_TRUNCATE = 'GL_TOOLTIP_ON_TRUNCATE';

const applyTooltip = (el, binding, vnode) => {
  const showTooltip = hasHorizontalOverflow(el);

  if (showTooltip) {
    GlTooltipDirective.bind(
      el,
      { ...binding, value: binding?.value || el.innerText?.trim() },
      vnode,
    );
  } else {
    GlTooltipDirective.unbind(el);
  }
};

const initTooltip = (el, binding, vnode) => {
  if (!el[GL_TOOLTIP_ON_TRUNCATE]) {
    el[GL_TOOLTIP_ON_TRUNCATE] = true;

    // Container may resize, set up observer
    GlResizeObserverDirective.bind(el, {
      value: debounce(() => {
        applyTooltip(el, binding, vnode);
      }, RESIZE_DEBOUNCE_WAIT_MS),
    });
  }
};

export default {
  bind(el, binding, vnode) {
    initTooltip(el, binding, vnode);
    applyTooltip(el, binding, vnode);
  },

  componentUpdated(el, binding, vnode) {
    nextTick(() => {
      applyTooltip(el, binding, vnode);
    });
  },

  unbind(el) {
    if (el[GL_TOOLTIP_ON_TRUNCATE]) {
      GlTooltipDirective.unbind(el);
      GlResizeObserverDirective.unbind(el);

      el[GL_TOOLTIP_ON_TRUNCATE] = null;
    }
  },
};
