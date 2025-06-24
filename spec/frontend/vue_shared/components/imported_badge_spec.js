import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';

describe('ImportedBadge', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(ImportedBadge, {
      propsData: {
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findSpan = () => wrapper.find('span');
  const findBadgeTooltip = () => getBinding(findBadge().element, 'gl-tooltip');

  it('renders "Imported" badge', () => {
    createComponent();

    expect(findSpan().exists()).toBe(false);
    expect(findBadge().text()).toBe('Imported');
  });

  it('renders span instead of badge when text-only', () => {
    createComponent({ props: { textOnly: true } });

    expect(findBadge().exists()).toBe(false);
    expect(findSpan().text()).toBe('Imported');
  });

  it('renders tooltip', () => {
    createComponent();

    expect(findBadgeTooltip().value).toBe('This item was imported from another instance.');
  });
});
