import { mount } from '@vue/test-utils';
import { GlBadge, GlTooltip } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import FeatureCardBadge from '~/security_configuration/components/feature_card_badge.vue';

describe('Feature card badge component', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = extendedWrapper(
      mount(FeatureCardBadge, {
        propsData,
      }),
    );
  };

  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('tooltip render', () => {
    describe.each`
      context                                             | badge                                         | badgeHref
      ${'href on a badge object'}                         | ${{ tooltipText: 'test', badgeHref: 'href' }} | ${undefined}
      ${'href as property '}                              | ${{ tooltipText: null, badgeHref: '' }}       | ${'link'}
      ${'default href no property on badge or component'} | ${{ tooltipText: null, badgeHref: '' }}       | ${undefined}
    `('given $context', ({ badge, badgeHref }) => {
      beforeEach(() => {
        createComponent({ badge, badgeHref });
      });

      it('should show badge when badge given in configuration and available', () => {
        expect(findTooltip().exists()).toBe(Boolean(badge && badge.tooltipText));
      });

      it('should render correct link if link is provided', () => {
        expect(findBadge().attributes().href).toEqual(badgeHref);
      });
    });
  });
});
