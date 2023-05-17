import { shallowMount, mount } from '@vue/test-utils';
import RunnerEditButton from '~/ci/runner/components/runner_edit_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('RunnerEditButton', () => {
  let wrapper;

  const getTooltipValue = () => getBinding(wrapper.element, 'gl-tooltip').value;

  const createComponent = ({ attrs = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(RunnerEditButton, {
      attrs,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Displays Edit text', () => {
    expect(wrapper.attributes('aria-label')).toBe('Edit');
  });

  it('Displays Edit tooltip', () => {
    expect(getTooltipValue()).toBe('Edit');
  });

  it('Renders a link and adds an href attribute', () => {
    createComponent({ attrs: { href: '/edit' }, mountFn: mount });

    expect(wrapper.element.tagName).toBe('A');
    expect(wrapper.attributes('href')).toBe('/edit');
  });
});
