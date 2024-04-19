import { GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { renderVueComponentForLegacyJS } from './render_vue_component_for_legacy_js';

const defaultValue = (prop) => GlLoadingIcon.props[prop]?.default;

/**
 * Returns a loading icon/spinner element.
 *
 * This should *only* be used in existing legacy areas of code where Vue is not
 * in use, as part of the migration strategy defined in
 * https://gitlab.com/groups/gitlab-org/-/epics/7626.
 *
 * @param {object} props - The props to configure the spinner.
 * @param {boolean} props.inline - Display the spinner inline; otherwise, as a block.
 * @param {string} props.color - The color of the spinner ('dark' or 'light')
 * @param {string} props.size - The size of the spinner ('sm', 'md', 'lg', 'xl')
 * @param {string[]} props.classes - Additional classes to apply to the element.
 * @param {string} props.label - The ARIA label to apply to the spinner.
 * @returns {HTMLElement}
 */
export const loadingIconForLegacyJS = ({
  inline = defaultValue('inline'),
  color = defaultValue('color'),
  size = defaultValue('size'),
  classes = [],
  label = __('Loading'),
} = {}) =>
  renderVueComponentForLegacyJS(GlLoadingIcon, {
    class: classes,
    props: {
      inline,
      color,
      size,
      label,
    },
  });
