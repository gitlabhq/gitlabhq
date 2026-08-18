import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initHomepage from '~/homepage/index';
import HomepageApp from '~/homepage/components/homepage_app.vue';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

jest.mock('~/lib/utils/vue3compat/init_vue_app', () => ({
  initVueApp: jest.fn(() => ({ mockApp: true })),
}));

jest.mock('~/lib/graphql', () => ({
  __esModule: true,
  default: jest.fn(() => ({})),
}));

// Stubbed to avoid loading the full (and heavy) homepage component tree;
// the bootstrap only forwards the component reference to initVueApp.
jest.mock('~/homepage/components/homepage_app.vue', () => ({
  __esModule: true,
  default: { name: 'MockHomepageApp', render: () => null },
}));

describe('Homepage index', () => {
  let mockElement;

  beforeEach(() => {
    setHTMLFixture(`
      <div
        id="js-homepage-app"
        data-review-requested-path="/review/requested"
        data-activity-path="/activity"
        data-assigned-merge-requests-path="/assigned/merge-requests"
        data-assigned-work-items-path="/assigned/work-items"
        data-authored-work-items-path="/authored/work-items"
        data-duo-code-review-bot-username="GitLabDuo"
        data-last-push-event='{"branch_name": "feature-branch", "project": {"name": "Test Project", "web_url": "/test-project"}, "created_at": "2023-01-01T00:00:00Z", "create_mr_path": "/create-mr"}'
      ></div>
    `);

    mockElement = document.getElementById('js-homepage-app');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('when element exists', () => {
    it('bootstraps the homepage app with the element data and returns the app', () => {
      const result = initHomepage();

      expect(initVueApp).toHaveBeenCalledWith({
        el: mockElement,
        name: 'HomepageAppRoot',
        provide: {
          duoCodeReviewBotUsername: 'GitLabDuo',
        },
        apolloProvider: expect.any(Object),
        component: HomepageApp,
        props: {
          reviewRequestedPath: '/review/requested',
          activityPath: '/activity',
          assignedMergeRequestsPath: '/assigned/merge-requests',
          assignedWorkItemsPath: '/assigned/work-items',
          authoredWorkItemsPath: '/authored/work-items',
          lastPushEvent: {
            branch_name: 'feature-branch',
            project: { name: 'Test Project', web_url: '/test-project' },
            created_at: '2023-01-01T00:00:00Z',
            create_mr_path: '/create-mr',
          },
        },
      });
      expect(result).toEqual({ mockApp: true });
    });

    describe.each([
      ['null', (el) => Object.assign(el.dataset, { lastPushEvent: null })],
      ['missing', (el) => delete el.dataset.lastPushEvent],
      ['empty string', (el) => Object.assign(el.dataset, { lastPushEvent: '' })],
    ])('when lastPushEvent is %s', (description, setLastPushEvent) => {
      it('passes a null lastPushEvent prop', () => {
        setLastPushEvent(mockElement);

        initHomepage();

        expect(initVueApp).toHaveBeenCalledWith(
          expect.objectContaining({
            props: expect.objectContaining({
              lastPushEvent: null,
            }),
          }),
        );
      });
    });
  });

  describe('when element does not exist', () => {
    it('returns false', () => {
      setHTMLFixture('<div></div>');

      const result = initHomepage();

      expect(result).toBe(false);
      expect(initVueApp).not.toHaveBeenCalled();
    });
  });

  describe('error handling', () => {
    it('throws for invalid JSON in lastPushEvent', () => {
      mockElement.dataset.lastPushEvent = 'invalid-json';

      expect(() => initHomepage()).toThrow();
      expect(initVueApp).not.toHaveBeenCalled();
    });
  });
});
