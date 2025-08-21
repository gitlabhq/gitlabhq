import { createWrapper } from '@vue/test-utils';
import initObservability from '~/observability/index';
import ObservabilityApp from '~/observability/components/app.vue';

jest.mock('~/observability/components/app.vue', () => ({
  name: 'ObservabilityApp',
  props: ['o11yUrl', 'path', 'authTokens', 'title'],
  data() {
    return {};
  },
  render(h) {
    return h('div', { class: 'observability-app' });
  },
}));

describe('Observability Index', () => {
  let appRoot;
  let wrapper;

  const createAppRoot = () => {
    appRoot = document.createElement('div');
    appRoot.setAttribute('id', 'js-observability');
    appRoot.dataset.o11yUrl = 'https://o11y.example.com';
    appRoot.dataset.path = 'traces-explorer';
    document.body.appendChild(appRoot);

    wrapper = createWrapper(initObservability());
  };

  afterEach(() => {
    if (appRoot) {
      appRoot.remove();
      appRoot = null;
    }
  });

  const findObservabilityApp = () => wrapper.findComponent(ObservabilityApp);

  describe('when there is no app root', () => {
    it('returns null', () => {
      expect(initObservability()).toBeNull();
    });
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
    });

    it('renders the app', () => {
      expect(findObservabilityApp().exists()).toBe(true);
    });
  });

  describe('authTokens processing', () => {
    it('transforms authTokens keys and filters non-authTokens keys', () => {
      const testAppRoot = document.createElement('div');
      testAppRoot.setAttribute('id', 'js-observability');
      testAppRoot.dataset.o11yUrl = 'https://o11y.example.com';
      testAppRoot.dataset.path = 'traces-explorer';
      testAppRoot.dataset.authTokensUserId = 'user123';
      testAppRoot.dataset.authTokensAccessJwt = 'access-token';
      testAppRoot.dataset.otherKey = 'other-value';
      testAppRoot.dataset.anotherKey = 'another-value';
      document.body.appendChild(testAppRoot);

      const testWrapper = createWrapper(initObservability());
      const observabilityApp = testWrapper.findComponent(ObservabilityApp);

      expect(observabilityApp.props('authTokens')).toEqual({
        userId: 'user123',
        accessJwt: 'access-token',
      });

      testAppRoot.remove();
    });
  });
});
