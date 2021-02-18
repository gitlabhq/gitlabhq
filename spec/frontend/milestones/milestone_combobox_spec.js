import { GlLoadingIcon, GlSearchBoxByType, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { ENTER_KEY } from '~/lib/utils/keys';
import MilestoneCombobox from '~/milestones/components/milestone_combobox.vue';
import createStore from '~/milestones/stores/';
import { projectMilestones, groupMilestones } from './mock_data';

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
      stubs: {
        GlSearchBoxByType: true,
      },
      store: createStore(),
    });
  };

  beforeEach(() => {
    const mock = new MockAdapter(axios);
    gon.api_version = 'v4';

    projectMilestonesApiCallSpy = jest
      .fn()
      .mockReturnValue([200, projectMilestones, { [X_TOTAL_HEADER]: '6' }]);

    groupMilestonesApiCallSpy = jest
      .fn()
      .mockReturnValue([200, groupMilestones, { [X_TOTAL_HEADER]: '6' }]);

    searchApiCallSpy = jest
      .fn()
      .mockReturnValue([200, projectMilestones, { [X_TOTAL_HEADER]: '6' }]);

    mock
      .onGet(`/api/v4/projects/${projectId}/milestones`)
      .reply((config) => projectMilestonesApiCallSpy(config));

    mock
      .onGet(`/api/v4/groups/${groupId}/milestones`)
      .reply((config) => groupMilestonesApiCallSpy(config));

    mock.onGet(`/api/v4/projects/${projectId}/search`).reply((config) => searchApiCallSpy(config));
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  //
  // Finders
  //
  const findButtonContent = () => wrapper.find('[data-testid="milestone-combobox-button-content"]');

  const findNoResults = () => wrapper.find('[data-testid="milestone-combobox-no-results"]');

  const findLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const findSearchBox = () => wrapper.find(GlSearchBoxByType);

  const findProjectMilestonesSection = () =>
    wrapper.find('[data-testid="project-milestones-section"]');
  const findProjectMilestonesDropdownItems = () =>
    findProjectMilestonesSection().findAll(GlDropdownItem);
  const findFirstProjectMilestonesDropdownItem = () => findProjectMilestonesDropdownItems().at(0);

  const findGroupMilestonesSection = () => wrapper.find('[data-testid="group-milestones-section"]');
  const findGroupMilestonesDropdownItems = () =>
    findGroupMilestonesSection().findAll(GlDropdownItem);
  const findFirstGroupMilestonesDropdownItem = () => findGroupMilestonesDropdownItems().at(0);

  //
  // Expecters
  //
  const projectMilestoneSectionContainsErrorMessage = () => {
    const projectMilestoneSection = findProjectMilestonesSection();

    return projectMilestoneSection
      .text()
      .includes('An error occurred while searching for milestones');
  };

  const groupMilestoneSectionContainsErrorMessage = () => {
    const groupMilestoneSection = findGroupMilestonesSection();

    return groupMilestoneSection
      .text()
      .includes('An error occurred while searching for milestones');
  };

  //
  // Convenience methods
  //
  const updateQuery = (newQuery) => {
    findSearchBox().vm.$emit('input', newQuery);
  };

  const selectFirstProjectMilestone = () => {
    findFirstProjectMilestonesDropdownItem().vm.$emit('click');
  };

  const selectFirstGroupMilestone = () => {
    findFirstGroupMilestonesDropdownItem().vm.$emit('click');
  };

  const waitForRequests = async ({ andClearMocks } = { andClearMocks: false }) => {
    await axios.waitForAll();
    if (andClearMocks) {
      projectMilestonesApiCallSpy.mockClear();
      groupMilestonesApiCallSpy.mockClear();
    }
  };

  describe('initialization behavior', () => {
    beforeEach(createComponent);

    it('initializes the dropdown with milestones when mounted', () => {
      return waitForRequests().then(() => {
        expect(projectMilestonesApiCallSpy).toHaveBeenCalledTimes(1);
        expect(groupMilestonesApiCallSpy).toHaveBeenCalledTimes(1);
      });
    });

    it('shows a spinner while network requests are in progress', () => {
      expect(findLoadingIcon().exists()).toBe(true);

      return waitForRequests().then(() => {
        expect(findLoadingIcon().exists()).toBe(false);
      });
    });

    it('shows additional links', () => {
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

    describe('when the Enter is pressed', () => {
      beforeEach(() => {
        createComponent();

        return waitForRequests({ andClearMocks: true });
      });

      it('requeries the search when Enter is pressed', () => {
        findSearchBox().vm.$emit('keydown', new KeyboardEvent({ key: ENTER_KEY }));

        return waitForRequests().then(() => {
          expect(searchApiCallSpy).toHaveBeenCalledTimes(1);
        });
      });
    });

    describe('when no results are found', () => {
      beforeEach(() => {
        projectMilestonesApiCallSpy = jest
          .fn()
          .mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

        groupMilestonesApiCallSpy = jest.fn().mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

        createComponent();

        return waitForRequests();
      });

      describe('when the search query is empty', () => {
        it('renders a "no results" message', () => {
          expect(findNoResults().text()).toBe('No matching results');
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
          expect(
            findProjectMilestonesSection()
              .find('[data-testid="milestone-results-section-header"]')
              .text(),
          ).toBe('Project milestones  6');
        });

        it("does not render an error message in the project milestone section's body", () => {
          expect(projectMilestoneSectionContainsErrorMessage()).toBe(false);
        });

        it('renders each project milestones as a selectable item', () => {
          const dropdownItems = findProjectMilestonesDropdownItems();

          projectMilestones.forEach((milestone, i) => {
            expect(dropdownItems.at(i).text()).toBe(milestone.title);
          });
        });
      });

      describe('when the project milestones search returns no results', () => {
        beforeEach(() => {
          projectMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(false);
        });
      });

      describe('when the project milestones search returns an error', () => {
        beforeEach(() => {
          projectMilestonesApiCallSpy = jest.fn().mockReturnValue([500]);
          searchApiCallSpy = jest.fn().mockReturnValue([500]);

          createComponent({ value: [] });

          return waitForRequests();
        });

        it('renders the project milestones section in the dropdown', () => {
          expect(findProjectMilestonesSection().exists()).toBe(true);
        });

        it("renders an error message in the project milestones section's body", () => {
          expect(projectMilestoneSectionContainsErrorMessage()).toBe(true);
        });
      });

      describe('selection', () => {
        beforeEach(() => {
          createComponent();

          return waitForRequests();
        });

        it('renders a checkmark by the selected item', async () => {
          selectFirstProjectMilestone();

          await nextTick();

          expect(
            findFirstProjectMilestonesDropdownItem().find('span').classes('selected-item'),
          ).toBe(true);

          selectFirstProjectMilestone();

          await nextTick();

          expect(
            findFirstProjectMilestonesDropdownItem().find('span').classes('selected-item'),
          ).toBe(false);
        });

        describe('when a project milestones is selected', () => {
          beforeEach(() => {
            createComponent();
            projectMilestonesApiCallSpy = jest
              .fn()
              .mockReturnValue([200, [{ title: 'v1.0' }], { [X_TOTAL_HEADER]: '1' }]);

            return waitForRequests();
          });

          it("displays the project milestones name in the dropdown's button", async () => {
            selectFirstProjectMilestone();
            await nextTick();

            expect(findButtonContent().text()).toBe('v1.0');

            selectFirstProjectMilestone();
            await nextTick();

            expect(findButtonContent().text()).toBe('No milestone');
          });

          it('updates the v-model binding with the project milestone title', async () => {
            selectFirstProjectMilestone();
            await nextTick();

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
          expect(
            findGroupMilestonesSection()
              .find('[data-testid="milestone-results-section-header"]')
              .text(),
          ).toBe('Group milestones  6');
        });

        it("does not render an error message in the group milestone section's body", () => {
          expect(groupMilestoneSectionContainsErrorMessage()).toBe(false);
        });

        it('renders each group milestones as a selectable item', () => {
          const dropdownItems = findGroupMilestonesDropdownItems();

          groupMilestones.forEach((milestone, i) => {
            expect(dropdownItems.at(i).text()).toBe(milestone.title);
          });
        });
      });

      describe('when the group milestones search returns no results', () => {
        beforeEach(() => {
          groupMilestonesApiCallSpy = jest
            .fn()
            .mockReturnValue([200, [], { [X_TOTAL_HEADER]: '0' }]);

          createComponent();

          return waitForRequests();
        });

        it('does not render the group milestones section in the dropdown', () => {
          expect(findGroupMilestonesSection().exists()).toBe(false);
        });
      });

      describe('when the group milestones search returns an error', () => {
        beforeEach(() => {
          groupMilestonesApiCallSpy = jest.fn().mockReturnValue([500]);
          searchApiCallSpy = jest.fn().mockReturnValue([500]);

          createComponent({ value: [] });

          return waitForRequests();
        });

        it('renders the group milestones section in the dropdown', () => {
          expect(findGroupMilestonesSection().exists()).toBe(true);
        });

        it("renders an error message in the group milestones section's body", () => {
          expect(groupMilestoneSectionContainsErrorMessage()).toBe(true);
        });
      });

      describe('selection', () => {
        beforeEach(() => {
          createComponent();

          return waitForRequests();
        });

        it('renders a checkmark by the selected item', async () => {
          selectFirstGroupMilestone();

          await nextTick();

          expect(findFirstGroupMilestonesDropdownItem().find('span').classes('selected-item')).toBe(
            true,
          );

          selectFirstGroupMilestone();

          await nextTick();

          expect(findFirstGroupMilestonesDropdownItem().find('span').classes('selected-item')).toBe(
            false,
          );
        });

        describe('when a group milestones is selected', () => {
          beforeEach(() => {
            createComponent();
            groupMilestonesApiCallSpy = jest
              .fn()
              .mockReturnValue([200, [{ title: 'group-v1.0' }], { [X_TOTAL_HEADER]: '1' }]);

            return waitForRequests();
          });

          it("displays the group milestones name in the dropdown's button", async () => {
            selectFirstGroupMilestone();
            await nextTick();

            expect(findButtonContent().text()).toBe('group-v1.0');

            selectFirstGroupMilestone();
            await nextTick();

            expect(findButtonContent().text()).toBe('No milestone');
          });

          it('updates the v-model binding with the group milestone title', async () => {
            selectFirstGroupMilestone();
            await nextTick();

            expect(wrapper.emitted().input[0][0]).toStrictEqual(['group-v1.0']);
          });
        });
      });
    });
  });
});
