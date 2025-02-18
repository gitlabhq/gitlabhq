import { GlEmptyState, GlSprintf, GlLink } from '@gitlab/ui';
import AgentEmptyState from '~/clusters_list/components/agent_empty_state.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';

const emptyStateImage = '/path/to/image';
const installDocsUrl = helpPagePath('user/clusters/agent/_index');

describe('AgentEmptyStateComponent', () => {
  let wrapper;
  const provideData = {
    emptyStateImage,
  };

  const findInstallDocsLink = () => wrapper.findComponent(GlLink);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    wrapper = shallowMountExtended(AgentEmptyState, {
      provide: provideData,
      stubs: { GlSprintf },
    });
  });

  it('renders the empty state', () => {
    expect(findEmptyState().exists()).toBe(true);
  });

  it('renders correct href attributes for the docs link', () => {
    expect(findInstallDocsLink().attributes('href')).toBe(installDocsUrl);
  });
});
