import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import ProjectSelect from '~/boards/components/project_select.vue';
import defaultState from '~/boards/stores/state';

import { mockList, mockActiveGroupProjects } from './mock_data';

const mockProjectsList1 = mockActiveGroupProjects.slice(0, 1);

describe('ProjectSelect component', () => {
  let wrapper;
  let store;

  const findLabel = () => wrapper.find("[data-testid='header-label']");
  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownLoadingIcon = () =>
    findGlDropdown().find('button:first-child').find(GlLoadingIcon);
  const findGlSearchBoxByType = () => wrapper.find(GlSearchBoxByType);
  const findGlDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findFirstGlDropdownItem = () => findGlDropdownItems().at(0);
  const findInMenuLoadingIcon = () => wrapper.find("[data-testid='dropdown-text-loading-icon']");
  const findEmptySearchMessage = () => wrapper.find("[data-testid='empty-result-message']");

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
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays a header title', () => {
    createWrapper();

    expect(findLabel().text()).toBe('Projects');
  });

  it('renders a default dropdown text', () => {
    createWrapper();

    expect(findGlDropdown().exists()).toBe(true);
    expect(findGlDropdown().text()).toContain('Select a project');
  });

  describe('when mounted', () => {
    it('displays a loading icon while projects are being fetched', async () => {
      createWrapper();

      expect(findGlDropdownLoadingIcon().exists()).toBe(true);

      await wrapper.vm.$nextTick();

      expect(findGlDropdownLoadingIcon().exists()).toBe(false);
    });
  });

  describe('when dropdown menu is open', () => {
    describe('by default', () => {
      beforeEach(() => {
        createWrapper({ activeGroupProjects: mockActiveGroupProjects });
      });

      it('shows GlSearchBoxByType with default attributes', () => {
        expect(findGlSearchBoxByType().exists()).toBe(true);
        expect(findGlSearchBoxByType().vm.$attrs).toMatchObject({
          placeholder: 'Search projects',
          debounce: '250',
        });
      });

      it("displays the fetched project's name", () => {
        expect(findFirstGlDropdownItem().exists()).toBe(true);
        expect(findFirstGlDropdownItem().text()).toContain(mockProjectsList1[0].name);
      });

      it("doesn't render loading icon in the menu", () => {
        expect(findInMenuLoadingIcon().isVisible()).toBe(false);
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

        findFirstGlDropdownItem().find('button').trigger('click');
      });

      it('renders the name of the selected project', () => {
        expect(findGlDropdown().find('.gl-new-dropdown-button-text').text()).toBe(
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
