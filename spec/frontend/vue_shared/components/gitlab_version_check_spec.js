import { GlBadge } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking } from 'helpers/tracking_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import axios from '~/lib/utils/axios_utils';
import GitlabVersionCheck from '~/vue_shared/components/gitlab_version_check.vue';

describe('GitlabVersionCheck', () => {
  let wrapper;
  let mock;

  const UPGRADE_DOCS_URL = helpPagePath('update/index');

  const defaultResponse = {
    code: 200,
    res: { severity: 'success' },
  };

  const createComponent = (mockResponse, propsData = {}) => {
    const response = {
      ...defaultResponse,
      ...mockResponse,
    };

    mock = new MockAdapter(axios);
    mock.onGet().replyOnce(response.code, response.res);

    wrapper = shallowMountExtended(GitlabVersionCheck, {
      propsData,
    });
  };

  const dummyGon = {
    relative_url_root: '/',
  };

  let originalGon;

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
    window.gon = originalGon;
  });

  const findGlBadgeClickWrapper = () => wrapper.findByTestId('badge-click-wrapper');
  const findGlBadge = () => wrapper.findComponent(GlBadge);

  describe.each`
    root                 | description
    ${'/'}               | ${'not used (uses its own (sub)domain)'}
    ${'/gitlab'}         | ${'custom path'}
    ${'/service/gitlab'} | ${'custom path with 2 depth'}
  `('path for version_check.json', ({ root, description }) => {
    describe(`when relative url is ${description}: ${root}`, () => {
      beforeEach(async () => {
        originalGon = window.gon;
        window.gon = { ...dummyGon };
        window.gon.relative_url_root = root;
        createComponent(defaultResponse);
        await waitForPromises(); // Ensure we wrap up the axios call
      });

      it('reflects the relative url setting', () => {
        expect(mock.history.get.length).toBe(1);

        const pathRegex = new RegExp(`^${root}`);
        expect(mock.history.get[0].url).toMatch(pathRegex);
      });
    });
  });

  describe('template', () => {
    describe.each`
      description               | mockResponse                                   | renders
      ${'successful but null'}  | ${{ code: 200, res: null }}                    | ${false}
      ${'successful and valid'} | ${{ code: 200, res: { severity: 'success' } }} | ${true}
      ${'an error'}             | ${{ code: 500, res: null }}                    | ${false}
    `('version_check.json response', ({ description, mockResponse, renders }) => {
      describe(`is ${description}`, () => {
        beforeEach(async () => {
          createComponent(mockResponse);
          await waitForPromises(); // Ensure we wrap up the axios call
        });

        it(`does${renders ? '' : ' not'} render Badge Click Wrapper and GlBadge`, () => {
          expect(findGlBadgeClickWrapper().exists()).toBe(renders);
          expect(findGlBadge().exists()).toBe(renders);
        });
      });
    });

    describe.each`
      mockResponse                                   | expectedUI
      ${{ code: 200, res: { severity: 'success' } }} | ${{ title: 'Up to date', variant: 'success' }}
      ${{ code: 200, res: { severity: 'warning' } }} | ${{ title: 'Update available', variant: 'warning' }}
      ${{ code: 200, res: { severity: 'danger' } }}  | ${{ title: 'Update ASAP', variant: 'danger' }}
    `('badge ui', ({ mockResponse, expectedUI }) => {
      describe(`when response is ${mockResponse.res.severity}`, () => {
        let trackingSpy;

        beforeEach(async () => {
          createComponent(mockResponse, { actionable: true });
          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
          await waitForPromises(); // Ensure we wrap up the axios call
        });

        it(`title is ${expectedUI.title}`, () => {
          expect(findGlBadge().text()).toBe(expectedUI.title);
        });

        it(`variant is ${expectedUI.variant}`, () => {
          expect(findGlBadge().attributes('variant')).toBe(expectedUI.variant);
        });

        it(`tracks rendered_version_badge with label ${expectedUI.title}`, () => {
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'rendered_version_badge', {
            label: expectedUI.title,
          });
        });

        it(`link is ${UPGRADE_DOCS_URL}`, () => {
          expect(findGlBadge().attributes('href')).toBe(UPGRADE_DOCS_URL);
        });

        it(`tracks click_version_badge with label ${expectedUI.title} when badge is clicked`, async () => {
          await findGlBadgeClickWrapper().trigger('click');

          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_version_badge', {
            label: expectedUI.title,
          });
        });
      });
    });

    describe('when actionable is false', () => {
      let trackingSpy;

      beforeEach(async () => {
        createComponent(defaultResponse, { actionable: false });
        trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        await waitForPromises(); // Ensure we wrap up the axios call
      });

      it('tracks rendered_version_badge correctly', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'rendered_version_badge', {
          label: 'Up to date',
        });
      });

      it('does not provide a link to GlBadge', () => {
        expect(findGlBadge().attributes('href')).toBe(undefined);
      });

      it('does not track click_version_badge', async () => {
        await findGlBadgeClickWrapper().trigger('click');

        expect(trackingSpy).not.toHaveBeenCalledWith(undefined, 'click_version_badge', {
          label: 'Up to date',
        });
      });
    });
  });
});
