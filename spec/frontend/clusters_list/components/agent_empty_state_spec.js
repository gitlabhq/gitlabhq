import { GlAlert, GlEmptyState, GlSprintf } from '@gitlab/ui';
import AgentEmptyState from '~/clusters_list/components/agent_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';

const emptyStateImage = '/path/to/image';
const projectPath = 'path/to/project';
const multipleClustersDocsUrl = helpPagePath('user/project/clusters/multiple_kubernetes_clusters');
const installDocsUrl = helpPagePath('administration/clusters/kas');

describe('AgentEmptyStateComponent', () => {
  let wrapper;

  const propsData = {
    hasConfigurations: false,
  };
  const provideData = {
    emptyStateImage,
    projectPath,
  };

  const findConfigurationsAlert = () => wrapper.findComponent(GlAlert);
  const findMultipleClustersDocsLink = () => wrapper.findByTestId('multiple-clusters-docs-link');
  const findInstallDocsLink = () => wrapper.findByTestId('install-docs-link');
  const findIntegrationButton = () => wrapper.findByTestId('integration-primary-button');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    wrapper = shallowMountExtended(AgentEmptyState, {
      propsData,
      provide: provideData,
      stubs: { GlEmptyState, GlSprintf },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('renders correct href attributes for the links', () => {
    expect(findMultipleClustersDocsLink().attributes('href')).toBe(multipleClustersDocsUrl);
    expect(findInstallDocsLink().attributes('href')).toBe(installDocsUrl);
  });

  describe('when there are no agent configurations in repository', () => {
    it('should render notification message box', () => {
      expect(findConfigurationsAlert().exists()).toBe(true);
    });

    it('should disable integration button', () => {
      expect(findIntegrationButton().attributes('disabled')).toBe('true');
    });
  });

  describe('when there is a list of agent configurations', () => {
    beforeEach(() => {
      propsData.hasConfigurations = true;
      wrapper = shallowMountExtended(AgentEmptyState, {
        propsData,
        provide: provideData,
      });
    });
    it('should render content without notification message box', () => {
      expect(findEmptyState().exists()).toBe(true);
      expect(findConfigurationsAlert().exists()).toBe(false);
      expect(findIntegrationButton().attributes('disabled')).toBeUndefined();
    });
  });
});
