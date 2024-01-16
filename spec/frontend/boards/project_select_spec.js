import { GlCollapsibleListbox, GlListboxItem, GlLoadingIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import groupProjectsQuery from '~/boards/graphql/group_projects.query.graphql';
import ProjectSelect from '~/boards/components/project_select.vue';

import { mockList, mockGroupProjectsResponse, mockProjects } from './mock_data';

Vue.use(VueApollo);

describe('ProjectSelect component', () => {
  let wrapper;
  let mockApollo;

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

  const projectsQueryHandler = jest.fn().mockResolvedValue(mockGroupProjectsResponse());
  const emptyProjectsQueryHandler = jest.fn().mockResolvedValue(mockGroupProjectsResponse([]));

  const createWrapper = ({ queryHandler = projectsQueryHandler, selectedProject = {} } = {}) => {
    mockApollo = createMockApollo([[groupProjectsQuery, queryHandler]]);
    wrapper = mountExtended(ProjectSelect, {
      apolloProvider: mockApollo,
      propsData: {
        list: mockList,
        selectedProject,
      },
      provide: {
        groupId: 1,
        fullPath: 'gitlab-org',
      },
      attachTo: document.body,
    });
  };

  describe('when mounted', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('displays a loading icon while projects are being fetched', async () => {
      expect(findGlDropdownLoadingIcon().exists()).toBe(true);

      await waitForPromises();

      expect(findGlDropdownLoadingIcon().exists()).toBe(false);
      expect(projectsQueryHandler).toHaveBeenCalled();
    });

    it('displays a header title', () => {
      expect(findLabel().text()).toBe('Projects');
    });

    it('renders a default dropdown text', () => {
      expect(findGlCollapsibleListBox().exists()).toBe(true);
      expect(findGlCollapsibleListBox().text()).toContain('Select a project');
    });

    it('passes down non archived projects to dropdown', async () => {
      findGlCollapsibleListBox().vm.$emit('shown');
      await nextTick();
      expect(findGlCollapsibleListBox().props('items').length).toEqual(mockProjects.length - 1);
    });
  });

  describe('when dropdown menu is open', () => {
    describe('by default', () => {
      beforeEach(async () => {
        createWrapper();
        await waitForPromises();
      });

      it('shows GlListboxSearchInput with placeholder text', () => {
        expect(findGlListboxSearchInput().exists()).toBe(true);
        expect(findGlListboxSearchInput().attributes('placeholder')).toBe('Search projects');
      });

      it("displays the fetched project's name", () => {
        expect(findFirstGlDropdownItem().exists()).toBe(true);
        expect(findFirstGlDropdownItem().text()).toContain(mockProjects[0].name);
      });

      it("doesn't render loading icon in the menu", () => {
        expect(findInMenuLoadingIcon().exists()).toBe(false);
      });

      it('does not render empty search result message', () => {
        expect(findEmptySearchMessage().exists()).toBe(false);
      });
    });

    describe('when no projects are being returned', () => {
      it('renders empty search result message', async () => {
        createWrapper({ queryHandler: emptyProjectsQueryHandler });
        await waitForPromises();

        expect(findEmptySearchMessage().exists()).toBe(true);
      });
    });

    describe('when a project is selected', () => {
      beforeEach(async () => {
        createWrapper({ selectedProject: mockProjects[0] });
        await waitForPromises();
      });

      it('renders the name of the selected project', () => {
        expect(findGlCollapsibleListBox().find('.gl-new-dropdown-button-text').text()).toBe(
          mockProjects[0].name,
        );
      });
    });

    describe('when projects are loading', () => {
      it('displays and hides gl-loading-icon while and after fetching data', async () => {
        createWrapper();
        await nextTick();
        expect(findInMenuLoadingIcon().isVisible()).toBe(true);
      });
    });
  });
});
