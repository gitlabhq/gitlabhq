import Vue from 'vue';
import * as Sentry from '@sentry/browser';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initGitlabVersionCheck from '~/gitlab_version_check';

describe('initGitlabVersionCheck', () => {
  let originalGon;
  let mock;
  let vueApps;

  const defaultResponse = {
    code: 200,
    res: { severity: 'success' },
  };

  const dummyGon = {
    relative_url_root: '/',
  };

  const createApp = async (mockResponse, htmlClass) => {
    originalGon = window.gon;

    const response = {
      ...defaultResponse,
      ...mockResponse,
    };

    mock = new MockAdapter(axios);
    mock.onGet().replyOnce(response.code, response.res);

    setHTMLFixture(`<div class="${htmlClass}"></div>`);

    vueApps = await initGitlabVersionCheck();
  };

  afterEach(() => {
    mock.restore();
    window.gon = originalGon;
    resetHTMLFixture();
  });

  describe('with no .js-gitlab-version-check-badge elements', () => {
    beforeEach(async () => {
      await createApp();
    });

    it('does not make axios GET request', () => {
      expect(mock.history.get.length).toBe(0);
    });

    it('does not render the Version Check Badge', () => {
      expect(vueApps).toBeNull();
    });
  });

  describe('with .js-gitlab-version-check-badge element but API errors', () => {
    beforeEach(async () => {
      jest.spyOn(Sentry, 'captureException');
      await createApp({ code: 500, res: null }, 'js-gitlab-version-check-badge');
    });

    it('does make axios GET request', () => {
      expect(mock.history.get.length).toBe(1);
      expect(mock.history.get[0].url).toContain('/admin/version_check.json');
    });

    it('logs error to Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
    });

    it('does not render the Version Check Badge', () => {
      expect(vueApps).toBeNull();
    });
  });

  describe('with .js-gitlab-version-check-badge element and successful API call', () => {
    beforeEach(async () => {
      await createApp({}, 'js-gitlab-version-check-badge');
    });

    it('does make axios GET request', () => {
      expect(mock.history.get.length).toBe(1);
      expect(mock.history.get[0].url).toContain('/admin/version_check.json');
    });

    it('does render the Version Check Badge', () => {
      expect(vueApps).toHaveLength(1);
      expect(vueApps[0]).toBeInstanceOf(Vue);
    });
  });

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
        await createApp({}, 'js-gitlab-version-check-badge');
      });

      it('reflects the relative url setting', () => {
        expect(mock.history.get.length).toBe(1);

        const pathRegex = new RegExp(`^${root}`);
        expect(mock.history.get[0].url).toMatch(pathRegex);
      });
    });
  });
});
