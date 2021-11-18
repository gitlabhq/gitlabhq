import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClustersActions from '~/clusters_list/components/clusters_actions.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { INSTALL_AGENT_MODAL_ID, CLUSTERS_ACTIONS } from '~/clusters_list/constants';

describe('ClustersActionsComponent', () => {
  let wrapper;

  const newClusterPath = 'path/to/create/cluster';
  const addClusterPath = 'path/to/connect/existing/cluster';

  const provideData = {
    newClusterPath,
    addClusterPath,
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findNewClusterLink = () => wrapper.findByTestId('new-cluster-link');
  const findConnectClusterLink = () => wrapper.findByTestId('connect-cluster-link');
  const findConnectNewAgentLink = () => wrapper.findByTestId('connect-new-agent-link');

  beforeEach(() => {
    wrapper = shallowMountExtended(ClustersActions, {
      provide: provideData,
      directives: {
        GlModalDirective: createMockDirective(),
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders actions menu', () => {
    expect(findDropdown().props('text')).toBe(CLUSTERS_ACTIONS.actionsButton);
  });

  it('renders a dropdown with 3 actions items', () => {
    expect(findDropdownItems()).toHaveLength(3);
  });

  it('renders correct href attributes for the links', () => {
    expect(findNewClusterLink().attributes('href')).toBe(newClusterPath);
    expect(findConnectClusterLink().attributes('href')).toBe(addClusterPath);
  });

  it('renders correct modal id for the agent link', () => {
    const binding = getBinding(findConnectNewAgentLink().element, 'gl-modal-directive');

    expect(binding.value).toBe(INSTALL_AGENT_MODAL_ID);
  });
});
