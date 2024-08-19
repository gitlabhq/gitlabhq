import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerEditButton from '~/ci/runner/components/runner_edit_button.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { I18N_EDIT } from '~/ci/runner/constants';

describe('RunnerEditButton', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);
  const getTooltipValue = () => getBinding(wrapper.element, 'gl-tooltip').value;

  const createComponent = ({ props = {}, mountFn = shallowMount, ...options } = {}) => {
    wrapper = mountFn(RunnerEditButton, {
      propsData: {
        href: '/edit',
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      ...options,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Displays Edit text', () => {
    expect(wrapper.attributes('aria-label')).toBe(I18N_EDIT);
  });

  it('Displays Edit tooltip', () => {
    expect(getTooltipValue()).toBe(I18N_EDIT);
  });

  it('Renders a link and adds an href attribute', () => {
    expect(findButton().attributes('href')).toBe('/edit');
  });

  describe('When no href is provided', () => {
    beforeEach(() => {
      createComponent({ props: { href: null } });
    });

    it('does not render', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
