import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlSearchBoxByType } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContextSwitcher from '~/super_sidebar/components/context_switcher.vue';
import FrequentProjectsList from '~/super_sidebar/components/frequent_projects_list.vue';
import FrequentGroupsList from '~/super_sidebar/components/frequent_groups_list.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import searchUserProjectsAndGroupsQuery from '~/super_sidebar/graphql/queries/search_user_groups_and_projects.query.graphql';
import { trackContextAccess, formatContextSwitcherItems } from '~/super_sidebar/utils';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';
import { searchUserProjectsAndGroupsResponseMock } from '../mock_data';

jest.mock('~/super_sidebar/utils', () => ({
  getStorageKeyFor: jest.requireActual('~/super_sidebar/utils').getStorageKeyFor,
  getTopFrequentItems: jest.requireActual('~/super_sidebar/utils').getTopFrequentItems,
  formatContextSwitcherItems: jest.requireActual('~/super_sidebar/utils')
    .formatContextSwitcherItems,
  trackContextAccess: jest.fn(),
}));

const username = 'root';
const projectsPath = 'projectsPath';
const groupsPath = 'groupsPath';

Vue.use(VueApollo);

describe('ContextSwitcher component', () => {
  let wrapper;
  let mockApollo;

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findFrequentProjectsList = () => wrapper.findComponent(FrequentProjectsList);
  const findFrequentGroupsList = () => wrapper.findComponent(FrequentGroupsList);

  const triggerSearchQuery = async () => {
    findSearchBox().vm.$emit('input', 'foo');
    await nextTick();
    jest.advanceTimersByTime(DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    return waitForPromises();
  };

  const searchUserProjectsAndGroupsHandlerSuccess = jest
    .fn()
    .mockResolvedValue(searchUserProjectsAndGroupsResponseMock);

  const createWrapper = ({ props = {}, requestHandlers = {} } = {}) => {
    mockApollo = createMockApollo([
      [
        searchUserProjectsAndGroupsQuery,
        requestHandlers.searchUserProjectsAndGroupsQueryHandler ??
          searchUserProjectsAndGroupsHandlerSuccess,
      ],
    ]);

    wrapper = shallowMountExtended(ContextSwitcher, {
      apolloProvider: mockApollo,
      propsData: {
        username,
        projectsPath,
        groupsPath,
        ...props,
      },
      stubs: {
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          props: ['placeholder'],
        }),
        FrequentProjectsList: stubComponent(FrequentProjectsList, {
          props: ['username', 'viewAllLink', 'isSearch', 'searchResults'],
        }),
        FrequentGroupsList: stubComponent(FrequentGroupsList, {
          props: ['username', 'viewAllLink', 'isSearch', 'searchResults'],
        }),
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('passes the placeholder to the search box', () => {
      expect(findSearchBox().props('placeholder')).toBe(
        s__('Navigation|Search for projects or groups'),
      );
    });

    it('passes the correct props the frequent projects list', () => {
      expect(findFrequentProjectsList().props()).toEqual({
        username,
        viewAllLink: projectsPath,
        isSearch: false,
        searchResults: [],
      });
    });

    it('passes the correct props the frequent groups list', () => {
      expect(findFrequentGroupsList().props()).toEqual({
        username,
        viewAllLink: groupsPath,
        isSearch: false,
        searchResults: [],
      });
    });

    it('does not trigger the search query on mount', () => {
      expect(searchUserProjectsAndGroupsHandlerSuccess).not.toHaveBeenCalled();
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

  describe('on search', () => {
    beforeEach(() => {
      createWrapper();
      return triggerSearchQuery();
    });

    it('triggers the search query on search', () => {
      expect(searchUserProjectsAndGroupsHandlerSuccess).toHaveBeenCalled();
    });

    it('removes the top border from the projects list', () => {
      expect(findFrequentProjectsList().attributes('class')).toContain('gl-border-t-0');
    });

    it('passes the projects to the frequent projects list', () => {
      expect(findFrequentProjectsList().props('isSearch')).toBe(true);
      expect(findFrequentProjectsList().props('searchResults')).toEqual(
        formatContextSwitcherItems(searchUserProjectsAndGroupsResponseMock.data.projects.nodes),
      );
    });

    it('passes the groups to the frequent groups list', () => {
      expect(findFrequentGroupsList().props('isSearch')).toBe(true);
      expect(findFrequentGroupsList().props('searchResults')).toEqual(
        formatContextSwitcherItems(searchUserProjectsAndGroupsResponseMock.data.user.groups.nodes),
      );
    });
  });

  describe('when search query does not match any items', () => {
    beforeEach(() => {
      createWrapper({
        requestHandlers: {
          searchUserProjectsAndGroupsQueryHandler: jest.fn().mockResolvedValue({
            data: {
              projects: {
                nodes: [],
              },
              user: {
                id: '1',
                groups: {
                  nodes: [],
                },
              },
            },
          }),
        },
      });
      return triggerSearchQuery();
    });

    it('passes empty results to the lists', () => {
      expect(findFrequentProjectsList().props('isSearch')).toBe(true);
      expect(findFrequentProjectsList().props('searchResults')).toEqual([]);
      expect(findFrequentGroupsList().props('isSearch')).toBe(true);
      expect(findFrequentGroupsList().props('searchResults')).toEqual([]);
    });
  });

  describe('when search query fails', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
    });

    it('captures exception if response is formatted incorrectly', async () => {
      createWrapper({
        requestHandlers: {
          searchUserProjectsAndGroupsQueryHandler: jest.fn().mockResolvedValue({
            data: {},
          }),
        },
      });
      await triggerSearchQuery();

      expect(Sentry.captureException).toHaveBeenCalled();
    });

    it('captures exception if query fails', async () => {
      createWrapper({
        requestHandlers: {
          searchUserProjectsAndGroupsQueryHandler: jest.fn().mockRejectedValue(),
        },
      });
      await triggerSearchQuery();

      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });
});
