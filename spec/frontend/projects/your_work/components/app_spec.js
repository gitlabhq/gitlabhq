import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import YourWorkProjectsApp from '~/projects/your_work/components/app.vue';
import { PROJECT_DASHBOARD_TABS } from '~/projects/your_work/constants';
import TabsWithList from '~/groups_projects/components/tabs_with_list.vue';

describe('YourWorkProjectsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(YourWorkProjectsApp);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders TabsWithList component and passes correct props', () => {
    expect(wrapper.findComponent(TabsWithList).props()).toEqual({
      tabs: PROJECT_DASHBOARD_TABS,
    });
  });
});
