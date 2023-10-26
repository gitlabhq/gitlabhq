import { GlLoadingIcon, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import MilestoneCombobox from '~/milestones/components/milestone_combobox.vue';
import createStore from '~/milestones/stores/';
import { projectMilestones, groupMilestones } from '../mock_data';

const extraLinks = [
  { text: 'Create new', url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/-/milestones/new' },
  { text: 'Manage milestones', url: '/h5bp/html5-boilerplate/-/milestones' },
];

Vue.use(Vuex);

describe('Milestone combobox component', () => {
  const projectId = '8';
  const groupId = '24';
  const groupMilestonesAvailable = true;
  const X_TOTAL_HEADER = 'x-total';

  let wrapper;
  let projectMilestonesApiCallSpy;
  let groupMilestonesApiCallSpy;
  let searchApiCallSpy;

  const createComponent = (props = {}, attrs = {}) => {
    const propsData = {
      projectId,
      groupId,
      groupMilestonesAvailable,
      extraLinks,
      value: [],
      ...props,
    };

    wrapper = mount(MilestoneCombobox, {
      propsData,
      attrs,
      listeners: {
        // simulate a parent component v-model binding
        input: (selectedMilestone) => {
          // ugly hack because setProps plays bad with immediate watchers
          // see https://github.com/vuejs/vue-test-utils/issues/1140 and
          // https://github.com/vuejs/vue-test-utils/pull/1752
          propsData.value = selectedMilestone;
          wrapper.setProps({ value: selectedMilestone });
        },
      },
      store: createStore(),
    });
  };

  beforeEach(() => {
    const mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    projectMilestonesApiCallSpy = jest
      .fn()
      .mockReturnValue([HTTP_STATUS_OK, projectMilestones, { [X_TOTAL_HEADER]: '6' }]);

    groupMilestonesApiCallSpy = jest
      .fn()
      .mockReturnValue([HTTP_STATUS_OK, groupMilestones, { [X_TOTAL_HEADER]: '6' }]);

    searchApiCallSpy = jest
      .fn()
      .mockReturnValue([HTTP_STATUS_OK, projectMilestones, { [X_TOTAL_HEADER]: '6' }]);

    mock
      .onGet(`/api/v4/projects/${projectId}/milestones`)
      .reply((config) => projectMilestonesApiCallSpy(config));

    mock
      .onGet(`/api/v4/groups/${groupId}/milestones`)
      .reply((config) => groupMilestonesApiCallSpy(config));

    mock.onGet(`/api/v4/projects/${projectId}/search`).reply((config) => searchApiCallSpy(config));
  });

  //
  // Finders
  //
  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findButtonContent = () => wrapper.find('[data-testid="base-dropdown-toggle"]');
  const findNoResults = () => wrapper.find('[data-testid="listbox-no-results-text"]');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findProjectMilestonesSection = () =>
    findGlCollapsibleListbox().find('[data-testid="project-milestones-section"]');
  const findGroupMilestonesSection = () =>
    findGlCollapsibleListbox().find('[data-testid="group-milestones-section"]');
  const findDropdownItems = () => findGlCollapsibleListbox().findAllComponents(GlListboxItem);

  //
  // Convenience methods
  //
  const updateQuery = (newQuery) => {
    findGlCollapsibleListbox().vm.$emit('search', newQuery);
  };

  const selectItem = (item) => {
    findGlCollapsibleListbox().vm.$emit('select', item);
  };

  const waitForRequests = async ({ andClearMocks } = { andClearMocks: false }) => {
    await axios.waitForAll();
    if (andClearMocks) {
      projectMilestonesApiCallSpy.mockClear();
      groupMilestonesApiCallSpy.mockClear();
    }
  };

  describe('initialization behavior', () => {
    it('initializes the dropdown with milestones when mounted', () => {
      createComponent();

      return waitForRequests().then(() => {
        expect(projectMilestonesApiCallSpy).toHaveBeenCalledTimes(1);
        expect(groupMilestonesApiCallSpy).toHaveBeenCalledTimes(1);
      });
    });

    it('shows a spinner while network requests are in progress', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);

      return waitForRequests().then(() => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    it('shows additional links', () => {
      createComponent();

      const links = wrapper.findAll('[data-testid="milestone-combobox-extra-links"]');
      links.wrappers.forEach((item, idx) => {
        expect(item.text()).toBe(extraLinks[idx].text);
        expect(item.attributes('href')).toBe(extraLinks[idx].url);
      });
    });
  });

  describe('post-initialization behavior', () => {
    describe('when the parent component provides an `id` binding', () => {
      const id = '8';

      beforeEach(() => {
        createComponent({}, { id });

        return waitForRequests();
      });

      it('adds the provided ID to the GlDropdown instance', () => {
        expect(wrapper.attributes().id).toBe(id);
      });
    });

    describe('when milestones are pre-selected', () => {
      beforeEach(() => {
        createComponent({ value: projectMilestones });

        return waitForRequests();
      });

      it('renders the pre-selected milestones', () => {
        expect(findButtonContent().text()).toBe('v0.1 + 5 more');
      });
    });

    describe('when the search query is updated', () => {
      beforeEach(() => {
        createComponent();

        return waitForRequests({ andClearMocks: true });
      });

      it('requeries the search when the search query is updated', () => {
        updateQuery('v1.2.3');

        return waitForRequests().then(() => {
          expect(searchApiCallSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when no results are found', () => {
      beforeEach(() => {
        projectMilestonesApiCallSpy = jest
          .fn()
          .mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);

        groupMilestonesApiCallSpy = jest
          .fn()
          .mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);

        createComponent();

        return waitForRequests();
      });

      describe('when the search query is empty', () => {
        it('renders a "no results" message', () => {
          expect(findNoResults().text()).toBe('No results found');
        });
      });
    });

    describe('project milestones', () => {
      describe('when the project milestones search returns results', () => {
        beforeEach(() => {
          createComponent();

          return waitForRequests();
        });

        it('renders the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(true);
        });

        it('renders the "Project milestones" heading with a total number indicator', () => {
          expect(findProjectMilestonesSection().text()).toBe('Project milestones 6');
        });

        it('renders each project milestones as a selectable item', () => {
          const dropdownItems = findDropdownItems();

          projectMilestones.forEach((milestone) => {
            expect(dropdownItems.filter((x) => x.text() === milestone.title).exists()).toBe(true);
          });
        });
      });

      describe('when the project milestones search returns no results', () => {
        beforeEach(() => {
          projectMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(false);
        });
      });

      describe('when the project milestones search returns an error', () => {
        beforeEach(() => {
          projectMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR]);
          searchApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR]);

          createComponent({ value: [] });

          return waitForRequests();
        });

        it('does not render the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(false);
        });
      });

      describe('selection', () => {
        beforeEach(() => {
          createComponent();

          return waitForRequests();
        });

        describe('when a project milestone is selected', () => {
          const item = 'v1.0';

          beforeEach(() => {
            createComponent();
            projectMilestonesApiCallSpy = jest
              .fn()
              .mockReturnValue([HTTP_STATUS_OK, [{ title: 'v1.0' }], { [X_TOTAL_HEADER]: '1' }]);

            selectItem([item]);
            return waitForRequests();
          });

          it("displays the project milestones name in the dropdown's button", () => {
            expect(findButtonContent().text()).toBe(item);
          });

          it('updates the v-model binding with the project milestone title', () => {
            expect(wrapper.emitted().input[0][0]).toStrictEqual(['v1.0']);
          });
        });
      });
    });

    describe('group milestones', () => {
      describe('when the group milestones search returns results', () => {
        beforeEach(() => {
          createComponent();

          return waitForRequests();
        });

        it('renders the group milestones section in the dropdown', () => {
          expect(findGroupMilestonesSection().exists()).toBe(true);
        });

        it('renders the "Group milestones" heading with a total number indicator', () => {
          expect(findGroupMilestonesSection().text()).toBe('Group milestones 6');
        });

        it('renders each group milestones as a selectable item', () => {
          const dropdownItems = findDropdownItems();

          groupMilestones.forEach((milestone) => {
            expect(dropdownItems.filter((x) => x.text() === milestone.title).exists()).toBe(true);
          });
        });
      });

      describe('when the group milestones search returns no results', () => {
        beforeEach(() => {
          groupMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([HTTP_STATUS_OK, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the group milestones section in the dropdown', () => {
          expect(findGroupMilestonesSection().exists()).toBe(false);
        });
      });

      describe('when the group milestones search returns an error', () => {
        beforeEach(() => {
          groupMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR]);
          searchApiCallSpy = jest.fn().mockReturnValue([HTTP_STATUS_INTERNAL_SERVER_ERROR]);

          createComponent({ value: [] });

          return waitForRequests();
        });

        it('does not render the group milestones section', () => {
          expect(findGroupMilestonesSection().exists()).toBe(false);
        });
      });
    });
  });
});
