import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { GlDropdown, GlDropdownItem, GlSearchBoxByType, GlLoadingIcon } from '@gitlab/ui';
import defaultState from '~/boards/stores/state';

import ProjectSelect from '~/boards/components/project_select.vue';

import { mockList, mockGroupProjects } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

const actions = {
  fetchGroupProjects: jest.fn(),
  setSelectedProject: jest.fn(),
};

const createStore = (state = defaultState) => {
  return new Vuex.Store({
    state,
    actions,
  });
};

const mockProjectsList1 = mockGroupProjects.slice(0, 1);

describe('ProjectSelect component', () => {
  let wrapper;

  const findLabel = () => wrapper.find("[data-testid='header-label']");
  const findGlDropdown = () => wrapper.find(GlDropdown);
  const findGlDropdownLoadingIcon = () =>
    findGlDropdown().find('button:first-child').find(GlLoadingIcon);
  const findGlSearchBoxByType = () => wrapper.find(GlSearchBoxByType);
  const findGlDropdownItems = () => wrapper.findAll(GlDropdownItem);
  const findFirstGlDropdownItem = () => findGlDropdownItems().at(0);
  const findInMenuLoadingIcon = () => wrapper.find("[data-testid='dropdown-text-loading-icon']");
  const findEmptySearchMessage = () => wrapper.find("[data-testid='empty-result-message']");

  const createWrapper = (state = {}) => {
    const store = createStore({
      groupProjects: [],
      groupProjectsFlags: {
        isLoading: false,
        pageInfo: {
          hasNextPage: false,
        },
      },
      ...state,
    });

    wrapper = mount(ProjectSelect, {
      localVue,
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
        createWrapper({ groupProjects: mockGroupProjects });
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
        createWrapper({ groupProjects: mockProjectsList1 });

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
        createWrapper({ groupProjectsFlags: { isLoading: true } });
      });

      it('displays and hides gl-loading-icon while and after fetching data', () => {
        expect(findInMenuLoadingIcon().isVisible()).toBe(true);
      });
    });
  });
});
