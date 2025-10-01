import { GlIcon, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { PanelBreakpointInstance } from '~/panel_breakpoint_instance';
import CiVerificationBadge from '~/ci/catalog/components/shared/ci_verification_badge.vue';
import { VERIFICATION_LEVELS } from '~/ci/catalog/constants';

describe('Catalog Verification Badge', () => {
  let wrapper;

  const defaultProps = {
    resourceId: 'gid://gitlab/Ci::Catalog::Resource/36',
    showText: true,
    verificationLevel: 'GITLAB_MAINTAINED',
  };

  const findVerificationIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findVerificationText = () => wrapper.findByTestId('verification-badge-text');

  const createComponent = (props = defaultProps) => {
    wrapper = extendedWrapper(
      shallowMount(CiVerificationBadge, {
        propsData: {
          ...props,
        },
        stubs: {
          GlSprintf,
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
    verificationLevel                  | breakpoint | text                       | link                     | placement
    ${'GITLAB_MAINTAINED'}             | ${'sm'}    | ${'by GitLab'}             | ${'designated creators'} | ${'bottom'}
    ${'GITLAB_MAINTAINED'}             | ${'md'}    | ${'by GitLab'}             | ${'designated creators'} | ${'right'}
    ${'GITLAB_PARTNER_MAINTAINED'}     | ${'sm'}    | ${'by a GitLab Partner'}   | ${'designated creators'} | ${'bottom'}
    ${'VERIFIED_CREATOR_MAINTAINED'}   | ${'sm'}    | ${'by a verified creator'} | ${'component creators'}  | ${'bottom'}
    ${'VERIFIED_CREATOR_SELF_MANAGED'} | ${'sm'}    | ${'by a verified creator'} | ${'verified creators'}   | ${'bottom'}
  `(
    'when the resource is maintained $text',
    ({ verificationLevel, text, breakpoint, link, placement }) => {
      beforeEach(() => {
        jest.spyOn(PanelBreakpointInstance, 'getBreakpointSize').mockReturnValue(breakpoint);

        createComponent({ ...defaultProps, verificationLevel });
      });

      it('renders the correct icon', () => {
        expect(findVerificationIcon().props('name')).toBe(
          VERIFICATION_LEVELS[verificationLevel].icon,
        );
      });

      it('displays the correct badge text', () => {
        expect(findVerificationText().text()).toContain(
          VERIFICATION_LEVELS[verificationLevel].badgeText,
        );
      });

      it('displays the correct popover text and link', () => {
        expect(findPopover().props('placement')).toBe(placement);
        expect(findPopover().text().replace(/\s+/g, ' ')).toContain(text);

        expect(findPopover().findComponent(GlLink).text()).toContain(link);
      });
    },
  );
});
