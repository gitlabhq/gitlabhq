import { shallowMount } from '@vue/test-utils';
import { STATUS_OPEN } from '~/issues/constants';
import IssuableList from '~/vue_shared/issuable/list/components/issuable_list_root.vue';
import WorkItemsListApp from '~/work_items/list/components/work_items_list_app.vue';

describe('WorkItemsListApp component', () => {
  let wrapper;

  const findIssuableList = () => wrapper.findComponent(IssuableList);

  const mountComponent = () => {
    wrapper = shallowMount(WorkItemsListApp);
  };

  it('renders IssuableList component', () => {
    mountComponent();

    expect(findIssuableList().props()).toMatchObject({
      currentTab: STATUS_OPEN,
      issuables: [],
      namespace: 'work-items',
      recentSearchesStorageKey: 'issues',
      searchInputPlaceholder: 'Search or filter results...',
      searchTokens: [],
      sortOptions: [],
      tabs: WorkItemsListApp.issuableListTabs,
    });
  });
});
