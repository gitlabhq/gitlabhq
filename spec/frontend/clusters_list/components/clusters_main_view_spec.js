import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClustersMainView from '~/clusters_list/components/clusters_main_view.vue';
import InstallAgentModal from '~/clusters_list/components/install_agent_modal.vue';
import {
  AGENT,
  CERTIFICATE_BASED,
  CLUSTERS_TABS,
  MAX_CLUSTERS_LIST,
  MAX_LIST_COUNT,
} from '~/clusters_list/constants';

const defaultBranchName = 'default-branch';

describe('ClustersMainViewComponent', () => {
  let wrapper;

  const propsData = {
    defaultBranchName,
  };

  beforeEach(() => {
    wrapper = shallowMountExtended(ClustersMainView, {
      propsData,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findAllTabs = () => wrapper.findAllComponents(GlTab);
  const findGlTabAtIndex = (index) => findAllTabs().at(index);
  const findComponent = () => wrapper.findByTestId('clusters-tab-component');
  const findModal = () => wrapper.findComponent(InstallAgentModal);

  it('renders `GlTabs` with `syncActiveTabWithQueryParams` and `queryParamName` props set', () => {
    expect(findTabs().exists()).toBe(true);
    expect(findTabs().props('syncActiveTabWithQueryParams')).toBe(true);
  });

  it('renders correct number of tabs', () => {
    expect(findAllTabs()).toHaveLength(CLUSTERS_TABS.length);
  });

  it('passes child-component param to the component', () => {
    expect(findComponent().props('defaultBranchName')).toBe(defaultBranchName);
  });

  it('passes correct max-agents param to the modal', () => {
    expect(findModal().props('maxAgents')).toBe(MAX_CLUSTERS_LIST);
  });

  describe('tabs', () => {
    it.each`
      tabTitle               | queryParamValue      | lineNumber
      ${'All'}               | ${'all'}             | ${0}
      ${'Agent'}             | ${AGENT}             | ${1}
      ${'Certificate based'} | ${CERTIFICATE_BASED} | ${2}
    `(
      'renders correct tab title and query param value',
      ({ tabTitle, queryParamValue, lineNumber }) => {
        expect(findGlTabAtIndex(lineNumber).attributes('title')).toBe(tabTitle);
        expect(findGlTabAtIndex(lineNumber).props('queryParamValue')).toBe(queryParamValue);
      },
    );
  });

  describe('when the child component emits the tab change event', () => {
    beforeEach(() => {
      findComponent().vm.$emit('changeTab', AGENT);
    });
    it('changes the tab', () => {
      expect(findTabs().attributes('value')).toBe('1');
    });

    it('passes correct max-agents param to the modal', () => {
      expect(findModal().props('maxAgents')).toBe(MAX_LIST_COUNT);
    });
  });
});
