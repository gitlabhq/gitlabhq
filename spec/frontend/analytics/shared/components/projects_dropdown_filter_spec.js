import { GlDropdown, GlDropdownItem, GlTruncate, GlSearchBoxByType } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
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

const MockGlDropdown = stubComponent(GlDropdown, {
  template: `
  <div>
    <slot name="header"></slot>
    <div data-testid="vsa-highlighted-items">
      <slot name="highlighted-items"></slot>
    </div>
    <div data-testid="vsa-default-items"><slot></slot></div>
  </div>
  `,
});

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

  const createComponent = (props = {}, stubs = {}) => {
    spyQuery = defaultMocks.$apollo.query;
    wrapper = mountExtended(ProjectsDropdownFilter, {
      mocks: { ...defaultMocks },
      propsData: {
        groupId: 1,
        groupNamespace: 'gitlab-org',
        ...props,
      },
      stubs,
    });
  };

  const createWithMockDropdown = (props) => {
    createComponent(props, { GlDropdown: MockGlDropdown });
    return waitForPromises();
  };

  const findHighlightedItems = () => wrapper.findByTestId('vsa-highlighted-items');
  const findUnhighlightedItems = () => wrapper.findByTestId('vsa-default-items');
  const findClearAllButton = () => wrapper.findByText('Clear all');
  const findSelectedProjectsLabel = () => wrapper.findComponent(GlTruncate);

  const findDropdown = () => wrapper.findComponent(GlDropdown);

  const findDropdownItems = () =>
    findDropdown()
      .findAllComponents(GlDropdownItem)
      .filter((w) => w.text() !== 'No matching results');

  const findDropdownAtIndex = (index) => findDropdownItems().at(index);

  const findDropdownButton = () => findDropdown().find('.dropdown-toggle');
  const findDropdownButtonAvatar = () => findDropdown().find('.gl-avatar');
  const findDropdownButtonAvatarAtIndex = (index) =>
    findDropdownAtIndex(index).find('img.gl-avatar');
  const findDropdownButtonIdentIconAtIndex = (index) =>
    findDropdownAtIndex(index).find('div.gl-avatar-identicon');

  const findDropdownNameAtIndex = (index) =>
    findDropdownAtIndex(index).find('[data-testid="project-name"');
  const findDropdownFullPathAtIndex = (index) =>
    findDropdownAtIndex(index).find('[data-testid="project-full-path"]');

  const selectDropdownItemAtIndex = async (index) => {
    findDropdownAtIndex(index).find('button').trigger('click');
    await nextTick();
  };

  // NOTE: Selected items are now visually separated from unselected items
  const findSelectedDropdownItems = () => findHighlightedItems().findAllComponents(GlDropdownItem);

  const findSelectedDropdownAtIndex = (index) => findSelectedDropdownItems().at(index);
  const findSelectedButtonIdentIconAtIndex = (index) =>
    findSelectedDropdownAtIndex(index).find('div.gl-avatar-identicon');
  const findSelectedButtonAvatarItemAtIndex = (index) =>
    findSelectedDropdownAtIndex(index).find('img.gl-avatar');

  const selectedIds = () => wrapper.vm.selectedProjects.map(({ id }) => id);

  const findSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);

  describe('queryParams are applied when fetching data', () => {
    beforeEach(() => {
      createComponent({
        queryParams: {
          first: 50,
          includeSubgroups: true,
        },
      });
    });

    it('applies the correct queryParams when making an api call', async () => {
      findSearchBoxByType().vm.$emit('input', 'gitlab');

      expect(spyQuery).toHaveBeenCalledTimes(1);

      await nextTick();
      expect(spyQuery).toHaveBeenCalledWith({
        query: getProjects,
        variables: {
          search: 'gitlab',
          groupFullPath: wrapper.vm.groupNamespace,
          first: 50,
          includeSubgroups: true,
        },
      });
    });
  });

  describe('highlighted items', () => {
    const blockDefaultProps = { multiSelect: true };

    beforeEach(() => {
      createComponent(blockDefaultProps);
    });

    describe('with no project selected', () => {
      it('does not render the highlighted items', async () => {
        await createWithMockDropdown(blockDefaultProps);

        expect(findSelectedDropdownItems().length).toBe(0);
      });

      it('renders the default project label text', () => {
        expect(findSelectedProjectsLabel().text()).toBe('Select projects');
      });

      it('does not render the clear all button', () => {
        expect(findClearAllButton().exists()).toBe(false);
      });
    });

    describe('with a selected project', () => {
      beforeEach(async () => {
        await selectDropdownItemAtIndex(0);
      });

      it('renders the highlighted items', async () => {
        await createWithMockDropdown(blockDefaultProps);
        await selectDropdownItemAtIndex(0);

        expect(findSelectedDropdownItems().length).toBe(1);
      });

      it('renders the highlighted items title', () => {
        expect(findSelectedProjectsLabel().text()).toBe(projects[0].name);
      });

      it('renders the clear all button', () => {
        expect(findClearAllButton().exists()).toBe(true);
      });

      it('clears all selected items when the clear all button is clicked', async () => {
        await selectDropdownItemAtIndex(1);

        expect(findSelectedProjectsLabel().text()).toBe('2 projects selected');

        await findClearAllButton().trigger('click');

        expect(findSelectedProjectsLabel().text()).toBe('Select projects');
      });
    });
  });

  describe('with a selected project and search term', () => {
    beforeEach(async () => {
      await createWithMockDropdown({ multiSelect: true });

      selectDropdownItemAtIndex(0);
      findSearchBoxByType().vm.$emit('input', 'this is a very long search string');
    });

    it('renders the highlighted items', () => {
      expect(findUnhighlightedItems().findAll('li').length).toBe(1);
    });

    it('hides the unhighlighted items that do not match the string', () => {
      expect(findUnhighlightedItems().findAll('li').length).toBe(1);
      expect(findUnhighlightedItems().text()).toContain('No matching results');
    });
  });

  describe('when passed an array of defaultProject as prop', () => {
    beforeEach(() => {
      createComponent({
        defaultProjects: [projects[0]],
      });
    });

    it("displays the defaultProject's name", () => {
      expect(findDropdownButton().text()).toContain(projects[0].name);
    });

    it("renders the defaultProject's avatar", () => {
      expect(findDropdownButtonAvatar().exists()).toBe(true);
    });

    it('marks the defaultProject as selected', () => {
      expect(findDropdownAtIndex(0).props('isChecked')).toBe(true);
    });
  });

  describe('when multiSelect is false', () => {
    const blockDefaultProps = { multiSelect: false };
    beforeEach(() => {
      createComponent(blockDefaultProps);
    });

    describe('displays the correct information', () => {
      it('contains 3 items', () => {
        expect(findDropdownItems()).toHaveLength(3);
      });

      it('renders an avatar when the project has an avatarUrl', () => {
        expect(findDropdownButtonAvatarAtIndex(0).exists()).toBe(true);
        expect(findDropdownButtonIdentIconAtIndex(0).exists()).toBe(false);
      });

      it("renders an identicon when the project doesn't have an avatarUrl", () => {
        expect(findDropdownButtonAvatarAtIndex(1).exists()).toBe(false);
        expect(findDropdownButtonIdentIconAtIndex(1).exists()).toBe(true);
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
      it('should emit the "selected" event with the selected project', () => {
        selectDropdownItemAtIndex(0);

        expect(wrapper.emitted().selected).toEqual([[[projects[0]]]]);
      });

      it('should change selection when new project is clicked', () => {
        selectDropdownItemAtIndex(1);

        expect(wrapper.emitted().selected).toEqual([[[projects[1]]]]);
      });

      it('selection should be emptied when a project is deselected', () => {
        selectDropdownItemAtIndex(0); // Select the item
        selectDropdownItemAtIndex(0); // deselect it

        expect(wrapper.emitted().selected).toEqual([[[projects[0]]], [[]]]);
      });

      it('renders an avatar in the dropdown button when the project has an avatarUrl', async () => {
        await createWithMockDropdown(blockDefaultProps);
        await selectDropdownItemAtIndex(0);

        expect(findSelectedButtonAvatarItemAtIndex(0).exists()).toBe(true);
        expect(findSelectedButtonIdentIconAtIndex(0).exists()).toBe(false);
      });

      it("renders an identicon in the dropdown button when the project doesn't have an avatarUrl", async () => {
        await createWithMockDropdown(blockDefaultProps);
        await selectDropdownItemAtIndex(1);

        expect(findSelectedButtonAvatarItemAtIndex(0).exists()).toBe(false);
        expect(findSelectedButtonIdentIconAtIndex(0).exists()).toBe(true);
      });
    });
  });

  describe('when multiSelect is true', () => {
    beforeEach(() => {
      createComponent({ multiSelect: true });
    });

    describe('displays the correct information', () => {
      it('contains 3 items', () => {
        expect(findDropdownItems()).toHaveLength(3);
      });

      it('renders an avatar when the project has an avatarUrl', () => {
        expect(findDropdownButtonAvatarAtIndex(0).exists()).toBe(true);
        expect(findDropdownButtonIdentIconAtIndex(0).exists()).toBe(false);
      });

      it("renders an identicon when the project doesn't have an avatarUrl", () => {
        expect(findDropdownButtonAvatarAtIndex(1).exists()).toBe(false);
        expect(findDropdownButtonIdentIconAtIndex(1).exists()).toBe(true);
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
      it('should add to selection when new project is clicked', () => {
        selectDropdownItemAtIndex(0);
        selectDropdownItemAtIndex(1);

        expect(selectedIds()).toEqual([projects[0].id, projects[1].id]);
      });

      it('should remove from selection when clicked again', () => {
        selectDropdownItemAtIndex(0);

        expect(selectedIds()).toEqual([projects[0].id]);

        selectDropdownItemAtIndex(0);

        expect(selectedIds()).toEqual([]);
      });

      it('renders the correct placeholder text when multiple projects are selected', async () => {
        selectDropdownItemAtIndex(0);
        selectDropdownItemAtIndex(1);
        await nextTick();

        expect(findDropdownButton().text()).toBe('2 projects selected');
      });
    });
  });
});
