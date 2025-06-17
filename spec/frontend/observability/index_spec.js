import { createWrapper } from '@vue/test-utils';
import initObservability from '~/observability/index';
import ObservabilityApp from '~/observability/components/app.vue';

jest.mock('~/observability/components/app.vue', () => ({
  name: 'ObservabilityApp',
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
});
