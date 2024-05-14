import { shallowMount } from '@vue/test-utils';
import { GlBanner, GlTableLite, GlBadge } from '@gitlab/ui';
import ApprovalsEmptyState from '~/deployments/components/approvals_empty_state.vue';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

describe('~/deployments/components/approvals_empty_state.vue', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const createComponent = ({ shouldShowCallout = true, propsData = {}, slots = {} } = {}) => {
    wrapper = shallowMount(ApprovalsEmptyState, {
      propsData,
      slots,
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
        GlBanner,
      },
    });
  };

  const findBanner = () => wrapper.findComponent(GlBanner);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findTable = () => wrapper.findComponent(GlTableLite);

  describe('when the callout is not dismissed', () => {
    it('shows the banner', () => {
      createComponent();

      expect(findBanner().exists()).toBe(true);
    });

    describe('with default values', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders default banner props', () => {
        expect(findBanner().props()).toMatchObject({
          title: 'Upgrade to get more our of your deployments',
          buttonText: 'Learn more',
          buttonLink: '/help/ci/environments/deployment_approvals',
        });
      });

      it('renders table header with the correct text', () => {
        expect(findBanner().text()).toContain(
          'Deployment approvals require a Premium or Ultimate subscription',
        );
      });

      it('renders table header with the premium badge', () => {
        expect(findBadge().props()).toMatchObject({ icon: 'license', variant: 'tier' });
        expect(findBadge().text()).toBe('GitLab Premium');
      });

      it('renders table with static data', () => {
        expect(findTable().props('fields')).toEqual([
          { key: 'approvers', label: 'Approvers' },
          { key: 'approvals', label: 'Approvals' },
          { key: 'approvedBy', label: 'Approved By' },
        ]);
      });

      it('renders CTA text in banner actions', () => {
        expect(findBanner().text()).toContain('Ready to use deployment approvals?');
      });
    });

    describe('with custom values', () => {
      it('renders default banner using values from props', () => {
        const bannerTitle = 'Custom title';
        const buttonText = 'Custom button text';
        const buttonLink = '/custom/link';

        createComponent({
          propsData: { bannerTitle, buttonText, buttonLink },
        });

        expect(findBanner().props()).toMatchObject({
          title: bannerTitle,
          buttonText,
          buttonLink,
        });
      });

      it('renders custom table-header slot', () => {
        createComponent({
          slots: { 'table-header': '<div>Custom table-header</div>' },
        });

        expect(findBanner().text()).toContain('Custom table-header');
      });

      it('renders custom banner-actions slot', () => {
        createComponent({
          slots: { 'banner-actions': '<div>Custom banner-actions</div>' },
        });

        expect(findBanner().text()).toContain('Custom banner-actions');
      });
    });
  });

  describe('when the callout is dismissed', () => {
    beforeEach(() => {
      createComponent({ shouldShowCallout: false });
    });

    it("doesn't show the banner", () => {
      expect(findBanner().exists()).toBe(false);
    });
  });
});
