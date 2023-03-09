import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import FrequentProjectsList from '~/super_sidebar/components//frequent_projects_list.vue';
import FrequentItemsList from '~/super_sidebar/components/frequent_items_list.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { MAX_FREQUENT_PROJECTS_COUNT } from '~/super_sidebar/constants';

const username = 'root';
const viewAllLink = '/path/to/projects';
const storageKey = `${username}/frequent-projects`;

describe('FrequentProjectsList component', () => {
  let wrapper;

  const findFrequentItemsList = () => wrapper.findComponent(FrequentItemsList);
  const findViewAllLink = () => wrapper.findComponent(NavItem);

  const createWrapper = () => {
    wrapper = shallowMountExtended(FrequentProjectsList, {
      propsData: {
        username,
        viewAllLink,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('passes the correct props to the frequent items list', () => {
    expect(findFrequentItemsList().props()).toEqual({
      title: s__('Navigation|FREQUENT PROJECTS'),
      storageKey,
      maxItems: MAX_FREQUENT_PROJECTS_COUNT,
    });
  });

  it('renders the "View all..." item', () => {
    expect(findViewAllLink().props('item')).toEqual({
      icon: 'project',
      link: viewAllLink,
      title: s__('Navigation|View all projects'),
    });
  });

  it('renders the empty text', () => {
    expect(wrapper.text()).toBe(s__('Navigation|Projects you visit often will appear here.'));
  });
});
