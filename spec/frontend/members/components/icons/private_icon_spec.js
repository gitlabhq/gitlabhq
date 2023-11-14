import { GlIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import PrivateIcon from '~/members/components/icons/private_icon.vue';

describe('PrivateIcon', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(PrivateIcon, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders private icon with tooltip', () => {
    const icon = wrapper.findComponent(GlIcon);
    const tooltipDirective = getBinding(icon.element, 'gl-tooltip');

    expect(icon.props('name')).toBe('eye-slash');
    expect(tooltipDirective.value).toBe(
      'Private group information is only accessible to its members.',
    );
  });
});
