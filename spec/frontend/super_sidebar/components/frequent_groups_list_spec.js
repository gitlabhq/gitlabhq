import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import FrequentGroupsList from '~/super_sidebar/components//frequent_groups_list.vue';
import FrequentItemsList from '~/super_sidebar/components/frequent_items_list.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import { MAX_FREQUENT_GROUPS_COUNT } from '~/super_sidebar/constants';

const username = 'root';
const viewAllLink = '/path/to/groups';
const storageKey = `${username}/frequent-groups`;

describe('FrequentGroupsList component', () => {
  let wrapper;

  const findFrequentItemsList = () => wrapper.findComponent(FrequentItemsList);
  const findViewAllLink = () => wrapper.findComponent(NavItem);

  const createWrapper = () => {
    wrapper = shallowMountExtended(FrequentGroupsList, {
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
      title: s__('Navigation|FREQUENT GROUPS'),
      storageKey,
      maxItems: MAX_FREQUENT_GROUPS_COUNT,
    });
  });

  it('renders the "View all..." item', () => {
    expect(findViewAllLink().props('item')).toEqual({
      icon: 'project',
      link: viewAllLink,
      title: s__('Navigation|View all groups'),
    });
  });

  it('renders the empty text', () => {
    expect(wrapper.text()).toBe(s__('Navigation|Groups you visit often will appear here.'));
  });
});
