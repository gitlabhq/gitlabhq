import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import GitlabVersionCheckBadge from '~/gitlab_version_check/components/gitlab_version_check_badge.vue';
import { STATUS_TYPES, UPGRADE_DOCS_URL } from '~/gitlab_version_check/constants';

describe('GitlabVersionCheckBadge', () => {
  let wrapper;
  let trackingSpy;

  const defaultProps = {
    status: STATUS_TYPES.SUCCESS,
  };

  const createComponent = (props = {}) => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

    wrapper = shallowMountExtended(GitlabVersionCheckBadge, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    unmockTracking();
  });

  const findVersionCheckBadge = () => wrapper.findByTestId('check-version-badge');
  const findGlBadge = () => wrapper.findComponent(GlBadge);

  describe('template', () => {
    describe.each`
      status                  | expectedUI
      ${STATUS_TYPES.SUCCESS} | ${{ title: 'Up to date', variant: 'success' }}
      ${STATUS_TYPES.WARNING} | ${{ title: 'Update available', variant: 'warning' }}
      ${STATUS_TYPES.DANGER}  | ${{ title: 'Update ASAP', variant: 'danger' }}
    `('badge ui', ({ status, expectedUI }) => {
      beforeEach(() => {
        createComponent({ status, actionable: true });
      });

      describe(`when status is ${status}`, () => {
        it(`title is ${expectedUI.title}`, () => {
          expect(findGlBadge().text()).toBe(expectedUI.title);
        });

        it(`variant is ${expectedUI.variant}`, () => {
          expect(findGlBadge().attributes('variant')).toBe(expectedUI.variant);
        });

        it(`tracks rendered_version_badge with label ${expectedUI.title}`, () => {
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
            label: 'version_badge',
            property: expectedUI.title,
          });
        });

        it(`link is ${UPGRADE_DOCS_URL}`, () => {
          expect(findGlBadge().attributes('href')).toBe(UPGRADE_DOCS_URL);
        });

        it(`tracks click_version_badge with label ${expectedUI.title} when badge is clicked`, async () => {
          await findVersionCheckBadge().trigger('click');

          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_link', {
            label: 'version_badge',
            property: expectedUI.title,
          });
        });
      });
    });

    describe('when actionable is false', () => {
      beforeEach(() => {
        createComponent({ actionable: false });
      });

      it('tracks rendered_version_badge correctly', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
          label: 'version_badge',
          property: 'Up to date',
        });
      });

      it('does not provide a link to GlBadge', () => {
        expect(findGlBadge().attributes('href')).toBe(undefined);
      });

      it('does not track click_version_badge', async () => {
        await findVersionCheckBadge().trigger('click');

        expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'click_link', {
          label: 'version_badge',
          property: 'Up to date',
        });
      });
    });
  });
});
