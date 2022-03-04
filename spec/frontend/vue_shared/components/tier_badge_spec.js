import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlIcon } from '@gitlab/ui';
import TierBadge from '~/vue_shared/components/tier_badge.vue';

describe('Tier badge component', () => {
  let wrapper;

  const createComponent = (props) =>
    shallowMount(TierBadge, {
      propsData: {
        ...props,
      },
    });

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findTierText = () => findBadge().text();
  const findIcon = () => wrapper.findComponent(GlIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('tiers name', () => {
    it.each`
      tier          | tierText
      ${'free'}     | ${'Free'}
      ${'premium'}  | ${'Premium'}
      ${'ultimate'} | ${'Ultimate'}
    `(
      'shows $tierText text in the badge and the license icon when $tier prop is passed',
      ({ tier, tierText }) => {
        wrapper = createComponent({ tier });
        expect(findTierText()).toBe(tierText);
        expect(findIcon().exists()).toBe(true);
        expect(findIcon().props().name).toBe('license');
      },
    );
  });

  describe('badge size', () => {
    const newSize = 'lg';

    beforeEach(() => {
      wrapper = createComponent({ tier: 'free', size: newSize });
    });

    it('passes down the size prop to the GlBadge component', () => {
      expect(findBadge().props().size).toBe(newSize);
    });
  });
});
