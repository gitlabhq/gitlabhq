import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JiraConnectApp from '~/jira_connect/components/app.vue';

describe('JiraConnectApp', () => {
  let wrapper;

  const findHeader = () => wrapper.findByTestId('new-jira-connect-ui-heading');
  const findHeaderText = () => findHeader().text();

  const createComponent = (options = {}) => {
    wrapper = extendedWrapper(
      shallowMount(JiraConnectApp, {
        provide: {
          glFeatures: { newJiraConnectUi: true },
        },
        ...options,
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('template', () => {
    it('renders new UI', () => {
      createComponent();

      expect(findHeader().exists()).toBe(true);
      expect(findHeaderText()).toBe('Linked namespaces');
    });

    describe('newJiraConnectUi is false', () => {
      it('does not render new UI', () => {
        createComponent({
          provide: {
            glFeatures: { newJiraConnectUi: false },
          },
        });

        expect(findHeader().exists()).toBe(false);
      });
    });
  });
});
