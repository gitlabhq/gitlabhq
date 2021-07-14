import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { TEST_HOST } from 'helpers/test_constants';
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

  const createComponent = (props = {}) => {
    spyQuery = defaultMocks.$apollo.query;
    wrapper = mount(ProjectsDropdownFilter, {
      mocks: { ...defaultMocks },
      propsData: {
        groupId: 1,
        groupNamespace: 'gitlab-org',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdown = () => wrapper.find(GlDropdown);

  const findDropdownItems = () =>
    findDropdown()
      .findAll(GlDropdownItem)
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

  const selectDropdownItemAtIndex = (index) =>
    findDropdownAtIndex(index).find('button').trigger('click');

  const selectedIds = () => wrapper.vm.selectedProjects.map(({ id }) => id);

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
      wrapper.setData({ searchTerm: 'gitlab' });

      expect(spyQuery).toHaveBeenCalledTimes(1);

      await wrapper.vm.$nextTick(() => {
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
  });

  describe('when passed a an array of defaultProject as prop', () => {
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
    beforeEach(() => {
      createComponent({ multiSelect: false });
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
        selectDropdownItemAtIndex(0);

        await wrapper.vm.$nextTick().then(() => {
          expect(findDropdownButtonAvatarAtIndex(0).exists()).toBe(true);
          expect(findDropdownButtonIdentIconAtIndex(0).exists()).toBe(false);
        });
      });

      it("renders an identicon in the dropdown button when the project doesn't have an avatarUrl", async () => {
        selectDropdownItemAtIndex(1);

        await wrapper.vm.$nextTick().then(() => {
          expect(findDropdownButtonAvatarAtIndex(1).exists()).toBe(false);
          expect(findDropdownButtonIdentIconAtIndex(1).exists()).toBe(true);
        });
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

        await wrapper.vm.$nextTick().then(() => {
          expect(findDropdownButton().text()).toBe('2 projects selected');
        });
      });
    });
  });
});
