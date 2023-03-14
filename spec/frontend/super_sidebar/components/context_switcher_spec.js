import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContextSwitcher from '~/super_sidebar/components/context_switcher.vue';
import FrequentProjectsList from '~/super_sidebar/components/frequent_projects_list.vue';
import FrequentGroupsList from '~/super_sidebar/components/frequent_groups_list.vue';
import { trackContextAccess } from '~/super_sidebar/utils';

jest.mock('~/super_sidebar/utils', () => ({
  getStorageKeyFor: jest.requireActual('~/super_sidebar/utils').getStorageKeyFor,
  getTopFrequentItems: jest.requireActual('~/super_sidebar/utils').getTopFrequentItems,
  trackContextAccess: jest.fn(),
}));

const username = 'root';
const projectsPath = 'projectsPath';
const groupsPath = 'groupsPath';

describe('ContextSwitcher component', () => {
  let wrapper;

  const findFrequentProjectsList = () => wrapper.findComponent(FrequentProjectsList);
  const findFrequentGroupsList = () => wrapper.findComponent(FrequentGroupsList);

  const createWrapper = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(ContextSwitcher, {
      propsData: {
        username,
        projectsPath,
        groupsPath,
        ...props,
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

  describe('item access tracking', () => {
    it('does not track anything if not within a trackable context', () => {
      createWrapper();

      expect(trackContextAccess).not.toHaveBeenCalled();
    });

    it('tracks item access if within a trackable context', () => {
      const currentContext = { namespace: 'groups' };
      createWrapper({
        props: {
          currentContext,
        },
      });

      expect(trackContextAccess).toHaveBeenCalledWith(username, currentContext);
    });
  });
});
