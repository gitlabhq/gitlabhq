import { GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ClustersMainView from '~/clusters_list/components/clusters_main_view.vue';
import { CLUSTERS_TABS } from '~/clusters_list/constants';

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

  describe('tabs', () => {
    it.each`
      tabTitle               | queryParamValue        | lineNumber
      ${'Agent'}             | ${'agent'}             | ${0}
      ${'Certificate based'} | ${'certificate_based'} | ${1}
    `(
      'renders correct tab title and query param value',
      ({ tabTitle, queryParamValue, lineNumber }) => {
        expect(findGlTabAtIndex(lineNumber).attributes('title')).toBe(tabTitle);
        expect(findGlTabAtIndex(lineNumber).props('queryParamValue')).toBe(queryParamValue);
      },
    );
  });
});
