import { GlEmptyState, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import AgentEmptyState from '~/clusters_list/components/agent_empty_state.vue';
import { INSTALL_AGENT_MODAL_ID } from '~/clusters_list/constants';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { helpPagePath } from '~/helpers/help_page_helper';

const emptyStateImage = '/path/to/image';
const installDocsUrl = helpPagePath('user/clusters/agent/index');

describe('AgentEmptyStateComponent', () => {
  let wrapper;
  const provideData = {
    emptyStateImage,
  };

  const findInstallDocsLink = () => wrapper.findComponent(GlLink);
  const findIntegrationButton = () => wrapper.findComponent(GlButton);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    wrapper = shallowMountExtended(AgentEmptyState, {
      provide: provideData,
      directives: {
        GlModalDirective: createMockDirective(),
      },
      stubs: { GlEmptyState, GlSprintf },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  it('renders the empty state', () => {
    expect(findEmptyState().exists()).toBe(true);
  });

  it('renders button for the agent registration', () => {
    expect(findIntegrationButton().exists()).toBe(true);
  });

  it('renders correct href attributes for the docs link', () => {
    expect(findInstallDocsLink().attributes('href')).toBe(installDocsUrl);
  });

  it('renders correct modal id for the agent registration modal', () => {
    const binding = getBinding(findIntegrationButton().element, 'gl-modal-directive');

    expect(binding.value).toBe(INSTALL_AGENT_MODAL_ID);
  });
});
