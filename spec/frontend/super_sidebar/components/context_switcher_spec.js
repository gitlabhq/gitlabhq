import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContextSwitcher from '~/super_sidebar/components/context_switcher.vue';
import FrequentProjectsList from '~/super_sidebar/components/frequent_projects_list.vue';
import FrequentGroupsList from '~/super_sidebar/components/frequent_groups_list.vue';

const username = 'root';
const projectsPath = 'projectsPath';
const groupsPath = 'groupsPath';

describe('ContextSwitcher component', () => {
  let wrapper;

  const findFrequentProjectsList = () => wrapper.findComponent(FrequentProjectsList);
  const findFrequentGroupsList = () => wrapper.findComponent(FrequentGroupsList);

  const createWrapper = () => {
    wrapper = shallowMountExtended(ContextSwitcher, {
      propsData: {
        username,
        projectsPath,
        groupsPath,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('passes the correct props the frequent projects list', () => {
    expect(findFrequentProjectsList().props()).toEqual({
      username,
      viewAllLink: projectsPath,
    });
  });

  it('passes the correct props the frequent groups list', () => {
    expect(findFrequentGroupsList().props()).toEqual({
      username,
      viewAllLink: groupsPath,
    });
  });
});
