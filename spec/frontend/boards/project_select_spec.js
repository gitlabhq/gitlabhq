import { GlCollapsibleListbox, GlListboxItem, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import ProjectSelect from '~/boards/components/project_select.vue';
import defaultState from '~/boards/stores/state';

import { mockActiveGroupProjects, mockList } from './mock_data';

const mockProjectsList1 = mockActiveGroupProjects.slice(0, 1);

describe('ProjectSelect component', () => {
  let wrapper;
  let store;

  const findLabel = () => wrapper.find("[data-testid='header-label']");
  const findGlCollapsibleListBox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findGlDropdownLoadingIcon = () =>
    findGlCollapsibleListBox()
      .find("[data-testid='base-dropdown-toggle'")
      .findComponent(GlLoadingIcon);
  const findGlListboxSearchInput = () =>
    wrapper.find("[data-testid='listbox-search-input'] > .gl-listbox-search-input");
  const findGlListboxItem = () => wrapper.findAllComponents(GlListboxItem);
  const findFirstGlDropdownItem = () => findGlListboxItem().at(0);
  const findInMenuLoadingIcon = () => wrapper.find("[data-testid='listbox-search-loader']");
  const findEmptySearchMessage = () => wrapper.find("[data-testid='listbox-no-results-text']");

  const createStore = ({ state, activeGroupProjects }) => {
    Vue.use(Vuex);

    store = new Vuex.Store({
      state: {
        defaultState,
        groupProjectsFlags: {
          isLoading: false,
          pageInfo: {
            hasNextPage: false,
          },
        },
        ...state,
      },
      actions: {
        fetchGroupProjects: jest.fn(),
        setSelectedProject: jest.fn(),
      },
      getters: {
        activeGroupProjects: () => activeGroupProjects,
      },
    });
  };

  const createWrapper = ({ state = {}, activeGroupProjects = [] } = {}) => {
    createStore({
      state,
      activeGroupProjects,
    });

    wrapper = mount(ProjectSelect, {
      propsData: {
        list: mockList,
      },
      store,
      provide: {
        groupId: 1,
      },
      attachTo: document.body,
    });
  };

  it('displays a header title', () => {
    createWrapper();

    expect(findLabel().text()).toBe('Projects');
  });

  it('renders a default dropdown text', () => {
    createWrapper();

    expect(findGlCollapsibleListBox().exists()).toBe(true);
    expect(findGlCollapsibleListBox().text()).toContain('Select a project');
  });

  describe('when mounted', () => {
    it('displays a loading icon while projects are being fetched', async () => {
      createWrapper();

      expect(findGlDropdownLoadingIcon().exists()).toBe(true);

      await nextTick();

      expect(findGlDropdownLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when dropdown menu is open', () => {
    describe('by default', () => {
      beforeEach(() => {
        createWrapper({ activeGroupProjects: mockActiveGroupProjects });
      });

      it('shows GlListboxSearchInput with placeholder text', () => {
        expect(findGlListboxSearchInput().exists()).toBe(true);
        expect(findGlListboxSearchInput().attributes('placeholder')).toBe('Search projects');
      });

      it("displays the fetched project's name", () => {
        expect(findFirstGlDropdownItem().exists()).toBe(true);
        expect(findFirstGlDropdownItem().text()).toContain(mockProjectsList1[0].name);
      });

      it("doesn't render loading icon in the menu", () => {
        expect(findInMenuLoadingIcon().exists()).toBe(false);
      });

      it('does not render empty search result message', () => {
        expect(findEmptySearchMessage().exists()).toBe(false);
      });
    });

    describe('when no projects are being returned', () => {
      it('renders empty search result message', () => {
        createWrapper();

        expect(findEmptySearchMessage().exists()).toBe(true);
      });
    });

    describe('when a project is selected', () => {
      beforeEach(() => {
        createWrapper({ activeGroupProjects: mockProjectsList1 });

        findFirstGlDropdownItem().find('li').trigger('click');
      });

      it('renders the name of the selected project', () => {
        expect(findGlCollapsibleListBox().find('.gl-new-dropdown-button-text').text()).toBe(
          mockProjectsList1[0].name,
        );
      });
    });

    describe('when projects are loading', () => {
      beforeEach(() => {
        createWrapper({ state: { groupProjectsFlags: { isLoading: true } } });
      });

      it('displays and hides gl-loading-icon while and after fetching data', () => {
        expect(findInMenuLoadingIcon().isVisible()).toBe(true);
      });
    });
  });
});
