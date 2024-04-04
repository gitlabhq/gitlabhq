import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CiVerificationBadge from '~/ci/catalog/components/shared/ci_verification_badge.vue';
import { VerificationLevel } from '~/ci/catalog/constants';

describe('Catalog Verification Badge', () => {
  let wrapper;

  const defaultProps = {
    resourceId: 'gid://gitlab/Ci::Catalog::Resource/36',
    showText: true,
    verificationLevel: 'GITLAB',
  };

  const findVerificationIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);
  const findVerificationText = () => wrapper.findByTestId('verification-badge-text');

  const createComponent = (props = defaultProps) => {
    wrapper = extendedWrapper(
      shallowMount(CiVerificationBadge, {
        propsData: {
          ...props,
        },
      }),
    );
  };

  describe('when the badge is rendered', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an icon', () => {
      expect(findVerificationIcon().exists()).toBe(true);
    });

    it('renders a link', () => {
      expect(findLink().exists()).toBe(true);
    });
  });

  describe('badge text', () => {
    describe('when showText is true', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders badge text', () => {
        expect(findVerificationText().exists()).toBe(true);
      });
    });

    describe('when showText is false', () => {
      beforeEach(() => {
        createComponent({ ...defaultProps, showText: false });
      });

      it('does not render badge text', () => {
        expect(findVerificationText().exists()).toBe(false);
      });
    });
  });

  describe.each`
    verificationLevel | describeText
    ${'GITLAB'}       | ${'GitLab'}
    ${'PARTNER'}      | ${'partner'}
  `('when the resource is $describeText maintained', ({ verificationLevel }) => {
    beforeEach(() => {
      createComponent({ ...defaultProps, verificationLevel });
    });

    it('renders the correct icon', () => {
      expect(findVerificationIcon().props('name')).toBe(VerificationLevel[verificationLevel].icon);
    });

    it('displays the correct badge text', () => {
      expect(findVerificationText().text()).toContain(
        VerificationLevel[verificationLevel].badgeText,
      );
    });
  });
});
