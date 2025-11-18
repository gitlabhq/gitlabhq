import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import ArchivedBadge from '~/issuable/components/archived_badge.vue';

describe('ArchivedBadge component', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(ArchivedBadge, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        issuableType: 'issue',
        ...propsData,
      },
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  it('displays archived badge with correct text', () => {
    createComponent();
    expect(findBadge().text()).toBe('Archived');
  });

  it('has correct info variant for blue color', () => {
    createComponent();
    expect(findBadge().props('variant')).toEqual('info');
  });

  it('has tooltip', () => {
    createComponent();
    expect(getBinding(wrapper.element, 'gl-tooltip')).not.toBeUndefined();
  });

  describe.each`
    issuableType      | expectedTooltip
    ${'issue'}        | ${'This issue belongs to an archived project and is read-only.'}
    ${'epic'}         | ${'This epic belongs to an archived project and is read-only.'}
    ${''}             | ${'This item belongs to an archived project and is read-only.'}
    ${'unknown_type'} | ${'This unknown_type belongs to an archived project and is read-only.'}
  `('when issuableType is "$issuableType"', ({ issuableType, expectedTooltip }) => {
    it('displays correct tooltip', () => {
      createComponent({ issuableType });
      expect(findBadge().attributes('title')).toBe(expectedTooltip);
    });
  });
});
