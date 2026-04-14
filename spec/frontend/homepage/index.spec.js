import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('vue', () => {
  const mockVueInstance = {
    $mount: jest.fn(),
  };

  const MockVue = jest.fn(() => mockVueInstance);
  MockVue.use = jest.fn();
  MockVue.mockInstance = mockVueInstance;

  return {
    __esModule: true,
    default: MockVue,
  };
});

jest.mock('vue-apollo', () => {
  const MockVueApollo = jest.fn(() => ({ mockVueApolloInstance: true }));
  return {
    __esModule: true,
    default: MockVueApollo,
  };
});

jest.mock('~/lib/graphql', () => ({
  __esModule: true,
  default: jest.fn(() => ({})),
}));

jest.mock('~/homepage/components/homepage_app.vue', () => ({
  __esModule: true,
  default: 'MockHomepageApp',
}));

describe('Homepage index', () => {
  let mockElement;
  let Vue;
  let VueApollo;
  let createDefaultClient;
  let initHomepage;

  beforeEach(async () => {
    jest.resetModules();

    // eslint-disable-next-line global-require
    Vue = require('vue').default;
    // eslint-disable-next-line global-require
    VueApollo = require('vue-apollo').default;
    // eslint-disable-next-line global-require
    createDefaultClient = require('~/lib/graphql').default;

    Vue.mockClear();
    Vue.use.mockClear();
    createDefaultClient.mockClear();

    const homepageModule = await import('~/homepage/index');
    initHomepage = homepageModule.default;

    setHTMLFixture(`
      <div
        id="js-homepage-app"
        data-review-requested-path="/review/requested"
        data-activity-path="/activity"
        data-assigned-merge-requests-path="/assigned/merge-requests"
        data-assigned-work-items-path="/assigned/work-items"
        data-authored-work-items-path="/authored/work-items"
        data-duo-code-review-bot-username="GitLabDuo"
        data-merge-requests-review-requested-title="Review Requested"
        data-merge-requests-your-merge-requests-title="Your Merge Requests"
        data-last-push-event='{"branch_name": "feature-branch", "project": {"name": "Test Project", "web_url": "/test-project"}, "created_at": "2023-01-01T00:00:00Z", "create_mr_path": "/create-mr"}'
      ></div>
    `);

    mockElement = document.getElementById('js-homepage-app');
  });

  afterEach(() => {
    resetHTMLFixture();
    jest.restoreAllMocks();
  });

  describe('when element exists', () => {
    it('initializes Vue app with correct setup', () => {
      const result = initHomepage();

      expect(Vue.use).toHaveBeenCalledWith(VueApollo);
      expect(createDefaultClient).toHaveBeenCalled();
      expect(Vue).toHaveBeenCalledWith(
        expect.objectContaining({
          el: mockElement,
          provide: {
            duoCodeReviewBotUsername: 'GitLabDuo',
            mergeRequestsReviewRequestedTitle: 'Review Requested',
            mergeRequestsYourMergeRequestsTitle: 'Your Merge Requests',
          },
          apolloProvider: expect.objectContaining({ mockVueApolloInstance: true }),
          render: expect.any(Function),
        }),
      );
      expect(result).toBe(Vue.mockInstance);
    });

    it('parses lastPushEvent from JSON string', () => {
      initHomepage();

      const vueCall = Vue.mock.calls[0];
      const vueConfig = vueCall[0];

      const mockCreateElement = jest.fn();
      vueConfig.render(mockCreateElement);

      expect(mockCreateElement).toHaveBeenCalledWith('MockHomepageApp', {
        props: expect.objectContaining({
          lastPushEvent: {
            branch_name: 'feature-branch',
            project: { name: 'Test Project', web_url: '/test-project' },
            created_at: '2023-01-01T00:00:00Z',
            create_mr_path: '/create-mr',
          },
        }),
      });
    });

    it('handles null lastPushEvent', () => {
      mockElement.dataset.lastPushEvent = null;

      initHomepage();

      const vueCall = Vue.mock.calls[0];
      const vueConfig = vueCall[0];

      const mockCreateElement = jest.fn();
      vueConfig.render(mockCreateElement);

      expect(mockCreateElement).toHaveBeenCalledWith('MockHomepageApp', {
        props: expect.objectContaining({
          lastPushEvent: null,
        }),
      });
    });

    it('handles undefined lastPushEvent', () => {
      delete mockElement.dataset.lastPushEvent;

      initHomepage();

      const vueCall = Vue.mock.calls[0];
      const vueConfig = vueCall[0];

      const mockCreateElement = jest.fn();
      vueConfig.render(mockCreateElement);

      expect(mockCreateElement).toHaveBeenCalledWith('MockHomepageApp', {
        props: expect.objectContaining({
          lastPushEvent: null,
        }),
      });
    });

    it('handles empty string lastPushEvent', () => {
      mockElement.dataset.lastPushEvent = '';

      initHomepage();

      const vueCall = Vue.mock.calls[0];
      const vueConfig = vueCall[0];

      const mockCreateElement = jest.fn();
      vueConfig.render(mockCreateElement);

      expect(mockCreateElement).toHaveBeenCalledWith('MockHomepageApp', {
        props: expect.objectContaining({
          lastPushEvent: null,
        }),
      });
    });
  });

  describe('when element does not exist', () => {
    it('returns false', () => {
      setHTMLFixture('<div></div>');

      const result = initHomepage();

      expect(result).toBe(false);
      expect(Vue).not.toHaveBeenCalled();
    });
  });

  describe('error handling', () => {
    it('handles invalid JSON in lastPushEvent', () => {
      setHTMLFixture(`
        <div
          id="js-homepage-app"
          data-review-requested-path="/review/requested"
          data-activity-path="/activity"
          data-assigned-merge-requests-path="/assigned/merge-requests"
          data-assigned-work-items-path="/assigned/work-items"
          data-authored-work-items-path="/authored/work-items"
          data-duo-code-review-bot-username="GitLabDuo"
          data-merge-requests-review-requested-title="Review Requested"
          data-merge-requests-your-merge-requests-title="Your Merge Requests"
          data-last-push-event="invalid-json"
        ></div>
      `);

      expect(() => initHomepage()).toThrow();
    });
  });
});
