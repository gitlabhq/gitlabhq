import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
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

  const createComponent = (mockResponse) => {
    const response = {
      ...defaultResponse,
      ...mockResponse,
    };

    mock = new MockAdapter(axios);
    mock.onGet().replyOnce(response.code, response.res);

    wrapper = shallowMount(GitlabVersionCheck);
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

        it(`does${renders ? '' : ' not'} render GlBadge`, () => {
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
        beforeEach(async () => {
          createComponent(mockResponse);
          await waitForPromises(); // Ensure we wrap up the axios call
        });

        it(`title is ${expectedUI.title}`, () => {
          expect(findGlBadge().text()).toBe(expectedUI.title);
        });

        it(`variant is ${expectedUI.variant}`, () => {
          expect(findGlBadge().attributes('variant')).toBe(expectedUI.variant);
        });

        it(`link is ${UPGRADE_DOCS_URL}`, () => {
          expect(findGlBadge().attributes('href')).toBe(UPGRADE_DOCS_URL);
        });
      });
    });
  });
});
