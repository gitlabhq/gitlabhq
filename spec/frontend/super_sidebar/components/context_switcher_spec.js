import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlDisclosureDropdown, GlSearchBoxByType, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import * as Sentry from '@sentry/browser';
import { s__ } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContextSwitcher from '~/super_sidebar/components/context_switcher.vue';
import ContextSwitcherToggle from '~/super_sidebar/components/context_switcher_toggle.vue';
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
const contextHeader = { avatar_shape: 'circle' };

Vue.use(VueApollo);

describe('ContextSwitcher component', () => {
  let wrapper;
  let mockApollo;

  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findContextSwitcherToggle = () => wrapper.findComponent(ContextSwitcherToggle);
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
        contextHeader,
        ...props,
      },
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          template: `
            <div>
              <slot name="toggle" />
              <slot />
            </div>
          `,
        }),
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

    it('passes the correct props to the frequent projects list', () => {
      expect(findProjectsList().props()).toEqual({
        username,
        viewAllLink: projectsPath,
        isSearch: false,
        searchResults: [],
      });
    });

    it('passes the correct props to the frequent groups list', () => {
      expect(findGroupsList().props()).toEqual({
        username,
        viewAllLink: groupsPath,
        isSearch: false,
        searchResults: [],
      });
    });

    it('does not trigger the search query on mount', () => {
      expect(searchUserProjectsAndGroupsHandlerSuccess).not.toHaveBeenCalled();
    });

    it('shows a loading spinner when search query is typed in', async () => {
      findSearchBox().vm.$emit('input', 'foo');
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('passes the correct props to the toggle', () => {
      expect(findContextSwitcherToggle().props('context')).toEqual(contextHeader);
      expect(findContextSwitcherToggle().props('expanded')).toEqual(false);
    });

    it("passes Popper.js' options to the disclosure dropdown", () => {
      expect(findDisclosureDropdown().props('popperOptions')).toMatchObject({
        modifiers: expect.any(Array),
      });
    });

    it('does not emit the `toggle` event initially', () => {
      expect(wrapper.emitted('toggle')).toBe(undefined);
    });
  });

  describe('visibility changes', () => {
    beforeEach(() => {
      createWrapper();
      findDisclosureDropdown().vm.$emit('shown');
    });

    it('emits the `toggle` event, focuses the search input and puts the toggle in the expanded state when opened', () => {
      expect(wrapper.emitted('toggle')).toHaveLength(1);
      expect(wrapper.emitted('toggle')[0]).toEqual([true]);
      expect(focusInputMock).toHaveBeenCalledTimes(1);
      expect(findContextSwitcherToggle().props('expanded')).toBe(true);
    });

    it("emits the `toggle` event, does not attempt to focus the input, and resets the toggle's `expanded` props to `false` when closed", async () => {
      findDisclosureDropdown().vm.$emit('hidden');
      await nextTick();

      expect(wrapper.emitted('toggle')).toHaveLength(2);
      expect(wrapper.emitted('toggle')[1]).toEqual([false]);
      expect(focusInputMock).toHaveBeenCalledTimes(1);
      expect(findContextSwitcherToggle().props('expanded')).toBe(false);
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
