import { GlButton, GlTruncate, GlCollapsibleListbox, GlListboxItem, GlAvatar } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import getProjects from '~/analytics/shared/graphql/projects.query.graphql';

const projects = [
  {
    id: 'gid://gitlab/Project/1',
    name: 'Gitlab Test',
    fullPath: 'gitlab-org/gitlab-test',
    avatarUrl: `${TEST_HOST}/images/home/nasa.svg`,
  },
  {
    id: 'gid://gitlab/Project/2',
    name: 'Gitlab Shell',
    fullPath: 'gitlab-org/gitlab-shell',
    avatarUrl: null,
  },
  {
    id: 'gid://gitlab/Project/3',
    name: 'Foo',
    fullPath: 'gitlab-org/foo',
    avatarUrl: null,
  },
];
const groupNamespace = 'gitlab-org';

const defaultMocks = {
  $apollo: {
    query: jest.fn().mockResolvedValue({
      data: { group: { projects: { nodes: projects } } },
    }),
  },
};

let spyQuery;

describe('ProjectsDropdownFilter component', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMountExtended, props = {}, stubs = {} } = {}) => {
    spyQuery = defaultMocks.$apollo.query;
    wrapper = mountFn(ProjectsDropdownFilter, {
      mocks: { ...defaultMocks },
      propsData: {
        groupId: 1,
        groupNamespace,
        ...props,
      },
      stubs: {
        GlButton,
        GlCollapsibleListbox,
        ...stubs,
      },
    });
  };

  const findSelectedProjectsLabel = () => wrapper.findComponent(GlTruncate);

  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

  const findDropdownItems = () => findDropdown().findAllComponents(GlListboxItem);

  const findDropdownAtIndex = (index) => findDropdownItems().at(index);

  const findDropdownButton = () => findDropdown().findComponent(GlButton);
  const findDropdownButtonAvatar = () => findDropdown().find('.gl-avatar');
  const findDropdownButtonAvatarAtIndex = (index) =>
    findDropdownAtIndex(index).findComponent(GlAvatar);
  const findDropdownButtonIdentIconAtIndex = (index) =>
    findDropdownAtIndex(index).find('div.gl-avatar-identicon');

  const findDropdownNameAtIndex = (index) =>
    findDropdownAtIndex(index).find('[data-testid="project-name"');
  const findDropdownFullPathAtIndex = (index) =>
    findDropdownAtIndex(index).find('[data-testid="project-full-path"]');

  const selectDropdownItemAtIndex = async (indexes, multi = true) => {
    const payload = indexes.map((index) => projects[index]?.id).filter(Boolean);
    findDropdown().vm.$emit('select', multi ? payload : payload[0]);
    await nextTick();
  };

  // NOTE: Selected items are now visually separated from unselected items
  const findSelectedDropdownItems = () =>
    findDropdownItems().filter((component) => component.props('isSelected') === true);

  const findSelectedDropdownAtIndex = (index) => findSelectedDropdownItems().at(index);
  const findSelectedButtonIdentIconAtIndex = (index) =>
    findSelectedDropdownAtIndex(index).find('div.gl-avatar-identicon');
  const findSelectedButtonAvatarItemAtIndex = (index) =>
    findSelectedDropdownAtIndex(index).find('img.gl-avatar');

  describe('when fetching data', () => {
    const mockQueryParams = {
      first: 50,
      includeSubgroups: true,
    };

    const mockVariables = {
      groupFullPath: groupNamespace,
      ...mockQueryParams,
    };

    beforeEach(() => {
      createComponent({
        props: {
          queryParams: mockQueryParams,
        },
      });

      spyQuery.mockClear();
    });

    it('should apply the correct queryParams when making an API call', async () => {
      findDropdown().vm.$emit('search', 'gitlab');

      await waitForPromises();

      expect(spyQuery).toHaveBeenCalledTimes(1);

      expect(spyQuery).toHaveBeenLastCalledWith({
        query: getProjects,
        variables: {
          search: 'gitlab',
          ...mockVariables,
        },
      });
    });

    it('should not make an API call when search query is below minimum search length', async () => {
      findDropdown().vm.$emit('search', 'hi');

      await waitForPromises();

      expect(spyQuery).toHaveBeenCalledTimes(0);
    });
  });

  describe('highlighted items', () => {
    const blockDefaultProps = { multiSelect: true };

    beforeEach(() => {
      createComponent({
        props: blockDefaultProps,
      });
    });

    describe('with no project selected', () => {
      it('does not render the highlighted items', () => {
        expect(findSelectedDropdownItems()).toHaveLength(0);
      });

      it('renders the default project label text', () => {
        createComponent({ mountFn: mountExtended, props: blockDefaultProps });

        expect(findSelectedProjectsLabel().text()).toBe('Select projects');
      });
    });

    describe('with a selected project', () => {
      beforeEach(() => {
        createComponent({
          mountFn: mountExtended,
          props: blockDefaultProps,
        });
      });

      it('renders the highlighted items', async () => {
        await selectDropdownItemAtIndex([0], false);

        expect(findSelectedDropdownItems()).toHaveLength(1);
      });

      it('renders the highlighted items title', async () => {
        await selectDropdownItemAtIndex([0], false);

        expect(findSelectedProjectsLabel().text()).toBe(projects[0].name);
      });

      it('clears all selected items when the clear all button is clicked', async () => {
        createComponent({
          mountFn: mountExtended,
          props: blockDefaultProps,
        });
        await waitForPromises();

        await selectDropdownItemAtIndex([0, 1]);

        expect(findSelectedProjectsLabel().text()).toBe('2 projects selected');

        await findDropdown().vm.$emit('reset');

        expect(findSelectedProjectsLabel().text()).toBe('Select projects');
      });
    });
  });

  describe('with a selected project and search term', () => {
    beforeEach(async () => {
      createComponent({
        props: { multiSelect: true },
      });
      await waitForPromises();

      await selectDropdownItemAtIndex([0]);

      findDropdown().vm.$emit('search', 'this is a very long search string');
    });

    it('renders the highlighted items', () => {
      expect(findSelectedDropdownItems()).toHaveLength(1);
    });

    it('hides the unhighlighted items that do not match the string', () => {
      expect(wrapper.find(`[name="Selected"]`).findAllComponents(GlListboxItem).length).toBe(1);
      expect(wrapper.find(`[name="Unselected"]`).findAllComponents(GlListboxItem).length).toBe(0);
    });
  });

  describe('when passed an array of defaultProject as prop', () => {
    beforeEach(async () => {
      createComponent({
        mountFn: mountExtended,
        props: {
          defaultProjects: [projects[0]],
        },
      });
      await waitForPromises();
    });

    it("displays the defaultProject's name", () => {
      expect(findDropdownButton().text()).toContain(projects[0].name);
    });

    it("renders the defaultProject's avatar", () => {
      expect(findDropdownButtonAvatar().exists()).toBe(true);
    });

    it('marks the defaultProject as selected', () => {
      expect(
        wrapper.findAll('[role="group"]').at(0).findAllComponents(GlListboxItem).at(0).text(),
      ).toContain(projects[0].name);
    });
  });

  describe('with an array of projects passed to `defaultProjects` and a search term', () => {
    const { name: searchQuery } = projects[2];

    beforeEach(async () => {
      createComponent({
        mountFn: mountExtended,
        props: {
          defaultProjects: [projects[0], projects[1]],
          multiSelect: true,
        },
      });

      await waitForPromises();

      findDropdown().vm.$emit('search', searchQuery);
    });

    it('should add search result to selected projects when selected', async () => {
      await selectDropdownItemAtIndex([0, 1, 2]);

      expect(findSelectedDropdownItems()).toHaveLength(3);
      expect(findDropdownButton().text()).toBe('3 projects selected');
    });
  });

  describe('when multiSelect is false', () => {
    const blockDefaultProps = { multiSelect: false };
    beforeEach(() => {
      createComponent({
        props: blockDefaultProps,
      });
    });

    describe('displays the correct information', () => {
      it('contains 3 items', () => {
        expect(findDropdownItems()).toHaveLength(3);
      });

      it('renders an avatar when the project has an avatarUrl', () => {
        expect(findDropdownButtonAvatarAtIndex(0).props('src')).toBe(projects[0].avatarUrl);
        expect(findDropdownButtonIdentIconAtIndex(0).exists()).toBe(false);
      });

      it("does not render an avatar when the project doesn't have an avatarUrl", () => {
        expect(findDropdownButtonAvatarAtIndex(1).props('src')).toEqual(null);
      });

      it('renders the project name', () => {
        projects.forEach((project, index) => {
          expect(findDropdownNameAtIndex(index).text()).toBe(project.name);
        });
      });

      it('renders the project fullPath', () => {
        projects.forEach((project, index) => {
          expect(findDropdownFullPathAtIndex(index).text()).toBe(project.fullPath);
        });
      });
    });

    describe('on project click', () => {
      it('should emit the "selected" event with the selected project', async () => {
        await selectDropdownItemAtIndex([0], false);

        expect(wrapper.emitted('selected')).toEqual([[[projects[0]]]]);
      });

      it('should change selection when new project is clicked', () => {
        selectDropdownItemAtIndex([1], false);

        expect(wrapper.emitted('selected')).toEqual([[[projects[1]]]]);
      });

      it('selection should be emptied when a project is deselected', async () => {
        await selectDropdownItemAtIndex([0], false); // Select the item
        await selectDropdownItemAtIndex([0], false);

        expect(wrapper.emitted('selected')).toEqual([[[projects[0]]], [[]]]);
      });

      it('renders an avatar in the dropdown button when the project has an avatarUrl', async () => {
        createComponent({
          mountFn: mountExtended,
          props: blockDefaultProps,
        });
        await waitForPromises();

        await selectDropdownItemAtIndex([0], false);

        expect(findSelectedButtonAvatarItemAtIndex(0).exists()).toBe(true);
        expect(findSelectedButtonIdentIconAtIndex(0).exists()).toBe(false);
      });

      it("renders an identicon in the dropdown button when the project doesn't have an avatarUrl", async () => {
        createComponent({
          mountFn: mountExtended,
          props: blockDefaultProps,
        });
        await waitForPromises();

        await selectDropdownItemAtIndex([1], false);
        expect(findSelectedButtonAvatarItemAtIndex(0).exists()).toBe(false);
        expect(findSelectedButtonIdentIconAtIndex(0).exists()).toBe(true);
      });
    });
  });

  describe('when multiSelect is true', () => {
    beforeEach(() => {
      createComponent({
        props: { multiSelect: true },
      });
    });

    describe('displays the correct information', () => {
      it('contains 3 items', () => {
        expect(findDropdownItems()).toHaveLength(3);
      });

      it('renders an avatar when the project has an avatarUrl', () => {
        expect(findDropdownButtonAvatarAtIndex(0).props('src')).toBe(projects[0].avatarUrl);
        expect(findDropdownButtonIdentIconAtIndex(0).exists()).toBe(false);
      });

      it("renders an identicon when the project doesn't have an avatarUrl", () => {
        expect(findDropdownButtonAvatarAtIndex(1).props('src')).toEqual(null);
      });

      it('renders the project name', () => {
        projects.forEach((project, index) => {
          expect(findDropdownNameAtIndex(index).text()).toBe(project.name);
        });
      });

      it('renders the project fullPath', () => {
        projects.forEach((project, index) => {
          expect(findDropdownFullPathAtIndex(index).text()).toBe(project.fullPath);
        });
      });
    });

    describe('on project click', () => {
      it('should add to selection when new project is clicked', async () => {
        await selectDropdownItemAtIndex([0, 1]);

        expect(findSelectedDropdownItems().at(0).text()).toContain(projects[1].name);
        expect(findSelectedDropdownItems().at(1).text()).toContain(projects[0].name);
      });

      it('should remove from selection when clicked again', async () => {
        await selectDropdownItemAtIndex([0]);

        expect(findSelectedDropdownItems().at(0).text()).toContain(projects[0].name);

        await selectDropdownItemAtIndex([]);

        expect(findSelectedDropdownItems()).toHaveLength(0);
      });

      it('renders the correct placeholder text when multiple projects are selected', async () => {
        createComponent({
          props: { multiSelect: true },
          mountFn: mountExtended,
        });
        await waitForPromises();

        await selectDropdownItemAtIndex([0, 1]);

        expect(findDropdownButton().text()).toBe('2 projects selected');
      });
    });
  });
});
