import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlSearchBoxByType, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContextSwitcher from '~/super_sidebar/components/context_switcher.vue';
import NavItem from '~/super_sidebar/components/nav_item.vue';
import ProjectsList from '~/super_sidebar/components/projects_list.vue';
import GroupsList from '~/super_sidebar/components/groups_list.vue';
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
const focusInputMock = jest.fn();

const persistentLinks = [
  { title: 'Explore', link: '/explore', icon: 'compass', link_classes: 'persistent-link-class' },
];
const username = 'root';
const projectsPath = 'projectsPath';
const groupsPath = 'groupsPath';

Vue.use(VueApollo);

describe('ContextSwitcher component', () => {
  let wrapper;
  let mockApollo;

  const findNavItems = () => wrapper.findAllComponents(NavItem);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findProjectsList = () => wrapper.findComponent(ProjectsList);
  const findGroupsList = () => wrapper.findComponent(GroupsList);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);

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
        persistentLinks,
        username,
        projectsPath,
        groupsPath,
        ...props,
      },
      stubs: {
        GlSearchBoxByType: stubComponent(GlSearchBoxByType, {
          props: ['placeholder'],
          methods: { focusInput: focusInputMock },
        }),
        ProjectsList: stubComponent(ProjectsList, {
          props: ['username', 'viewAllLink', 'isSearch', 'searchResults'],
        }),
        GroupsList: stubComponent(GroupsList, {
          props: ['username', 'viewAllLink', 'isSearch', 'searchResults'],
        }),
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the persistent links', () => {
      const navItems = findNavItems();
      const firstNavItem = navItems.at(0);

      expect(navItems.length).toBe(persistentLinks.length);
      expect(firstNavItem.props('item')).toBe(persistentLinks[0]);
      expect(firstNavItem.props('linkClasses')).toEqual({
        [persistentLinks[0].link_classes]: persistentLinks[0].link_classes,
      });
    });

    it('passes the placeholder to the search box', () => {
      expect(findSearchBox().props('placeholder')).toBe(
        s__('Navigation|Search your projects or groups'),
      );
    });

    it('passes the correct props the frequent projects list', () => {
      expect(findProjectsList().props()).toEqual({
        username,
        viewAllLink: projectsPath,
        isSearch: false,
        searchResults: [],
      });
    });

    it('passes the correct props the frequent groups list', () => {
      expect(findGroupsList().props()).toEqual({
        username,
        viewAllLink: groupsPath,
        isSearch: false,
        searchResults: [],
      });
    });

    it('focuses the search input when focusInput is called', () => {
      wrapper.vm.focusInput();

      expect(focusInputMock).toHaveBeenCalledTimes(1);
    });

    it('does not trigger the search query on mount', () => {
      expect(searchUserProjectsAndGroupsHandlerSuccess).not.toHaveBeenCalled();
    });

    it('shows a loading spinner when search query is typed in', async () => {
      findSearchBox().vm.$emit('input', 'foo');
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
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

    it('hides persistent links', () => {
      expect(findNavItems().length).toBe(0);
    });

    it('triggers the search query on search', () => {
      expect(searchUserProjectsAndGroupsHandlerSuccess).toHaveBeenCalled();
    });

    it('hides the loading spinner', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('passes the projects to the frequent projects list', () => {
      expect(findProjectsList().props('isSearch')).toBe(true);
      expect(findProjectsList().props('searchResults')).toEqual(
        formatContextSwitcherItems(searchUserProjectsAndGroupsResponseMock.data.projects.nodes),
      );
    });

    it('passes the groups to the frequent groups list', () => {
      expect(findGroupsList().props('isSearch')).toBe(true);
      expect(findGroupsList().props('searchResults')).toEqual(
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
      expect(findProjectsList().props('isSearch')).toBe(true);
      expect(findProjectsList().props('searchResults')).toEqual([]);
      expect(findGroupsList().props('isSearch')).toBe(true);
      expect(findGroupsList().props('searchResults')).toEqual([]);
    });
  });

  describe('when search query fails', () => {
    beforeEach(() => {
      jest.spyOn(Sentry, 'captureException');
    });

    it('captures exception and shows an alert if response is formatted incorrectly', async () => {
      createWrapper({
        requestHandlers: {
          searchUserProjectsAndGroupsQueryHandler: jest.fn().mockResolvedValue({
            data: {},
          }),
        },
      });
      await triggerSearchQuery();

      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findAlert().exists()).toBe(true);
    });

    it('captures exception and shows an alert if query fails', async () => {
      createWrapper({
        requestHandlers: {
          searchUserProjectsAndGroupsQueryHandler: jest.fn().mockRejectedValue(),
        },
      });
      await triggerSearchQuery();

      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findAlert().exists()).toBe(true);
    });
  });
});
