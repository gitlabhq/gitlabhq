import VueApollo from 'vue-apollo';
import Vue from 'vue';
import GetDefaultProjectsQuery from '~/explore/analytics_dashboards/components/get_default_projects.query.graphql';
import ProjectsFilter from '~/explore/analytics_dashboards/components/projects_filter.vue';
import ProjectsDropdownFilter from '~/analytics/shared/components/projects_dropdown_filter.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';

Vue.use(VueApollo);

describe('ProjectsFilter', () => {
  let wrapper;
  let mockHandler;

  const mockDefaultProjectA = {
    id: 'abc',
    fullPath: 'project/path',
    name: 'test-project',
    avatarUrl: 'avatarUrl',
  };

  const mockDefaultProjectB = {
    id: 'def',
    fullPath: 'project/pathB',
    name: 'test-projectB',
    avatarUrl: 'avatarUrl',
  };

  const createComponent = async (props = {}) => {
    mockHandler = jest.fn().mockResolvedValue({
      data: {
        projects: {
          nodes: props.multiSelect
            ? [mockDefaultProjectA, mockDefaultProjectB]
            : [mockDefaultProjectA],
        },
      },
    });

    const apolloProvider = createMockApollo([[GetDefaultProjectsQuery, mockHandler]]);

    wrapper = shallowMountExtended(ProjectsFilter, {
      apolloProvider,
      propsData: {
        groupNamespace: 'group/subgroup',
        ...props,
      },
    });

    await waitForPromises();
  };

  const findProjectsDropdownFilter = () => wrapper.findComponent(ProjectsDropdownFilter);

  describe('default', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('renders ProjectsDropdownFilter component', () => {
      expect(findProjectsDropdownFilter().exists()).toBe(true);
    });

    it('passes correct props to ProjectsDropdownFilter', () => {
      const dropdownFilter = findProjectsDropdownFilter();

      expect(dropdownFilter.props()).toMatchObject({
        toggleClasses: 'gl-max-w-26',
        queryParams: {
          first: 50,
          includeSubgroups: true,
        },
        groupNamespace: 'group/subgroup',
      });
    });

    it('does not set default projects', () => {
      expect(findProjectsDropdownFilter().props('defaultProjects')).toEqual([]);
    });

    it('does not load the defaultProjects', () => {
      expect(findProjectsDropdownFilter().props('loadingDefaultProjects')).toBe(false);
      expect(mockHandler).not.toHaveBeenCalled();
    });
  });

  describe('when projects[] query param is set', () => {
    beforeEach(() => {
      setWindowLocation(
        `?projects[]=${mockDefaultProjectA.id}&projects[]=${mockDefaultProjectB.id}`,
      );
    });

    describe('while loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets loadingDefaultProjects to true', () => {
        expect(findProjectsDropdownFilter().props('loadingDefaultProjects')).toBe(true);
      });
    });

    describe('when `multiSelect` prop is disabled', () => {
      beforeEach(() => {
        return createComponent();
      });

      it('sets the `multiSelect` prop on the dropdown', () => {
        expect(findProjectsDropdownFilter().props('multiSelect')).toBe(false);
      });

      it('loads the first default project', () => {
        expect(mockHandler).toHaveBeenCalledWith({ fullPaths: [mockDefaultProjectA.id] });
      });

      it('sets the defaultProjects', () => {
        expect(findProjectsDropdownFilter().props('defaultProjects')).toEqual([
          mockDefaultProjectA,
        ]);
      });

      it('sets loadingDefaultProjects to false', () => {
        expect(findProjectsDropdownFilter().props('loadingDefaultProjects')).toBe(false);
      });
    });

    describe('when `multiSelect` prop is enabled', () => {
      beforeEach(() => {
        return createComponent({ multiSelect: true });
      });

      it('sets the `multiSelect` prop on the dropdown', () => {
        expect(findProjectsDropdownFilter().props('multiSelect')).toBe(true);
      });

      it('loads the default projects', () => {
        expect(mockHandler).toHaveBeenCalledWith({
          fullPaths: [mockDefaultProjectA.id, mockDefaultProjectB.id],
        });
      });

      it('set the defaultProjects', () => {
        expect(findProjectsDropdownFilter().props('defaultProjects')).toEqual([
          mockDefaultProjectA,
          mockDefaultProjectB,
        ]);
      });
    });
  });

  describe('when projects query param is set without the `[]` suffix', () => {
    beforeEach(() => {
      setWindowLocation(`?projects=${mockDefaultProjectA.id}`);
      return createComponent();
    });

    it('loads the default project', () => {
      expect(mockHandler).toHaveBeenCalledWith({ fullPaths: [mockDefaultProjectA.id] });
    });
  });

  describe('onProjectsSelected', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('emits project-selected event with correct values when a project is selected', () => {
      expect(wrapper.emitted('project-selected')).toBeUndefined();

      const selectedProject = {
        fullPath: 'group/project',
        id: '123',
      };
      findProjectsDropdownFilter().vm.$emit('selected', [selectedProject]);

      expect(wrapper.emitted('project-selected')).toEqual([[[selectedProject]]]);
    });

    it('emits project-selected event with empty list when no project is selected (e.g. selection cleared)', () => {
      findProjectsDropdownFilter().vm.$emit('selected', []);

      expect(wrapper.emitted('project-selected')).toEqual([[[]]]);
    });
  });

  describe('disabled prop', () => {
    it('defaults to passing disabled=false to the dropdown filter', async () => {
      await createComponent();

      expect(findProjectsDropdownFilter().props('disabled')).toBe(false);
    });

    it('forwards disabled=true to the dropdown filter when set', async () => {
      await createComponent({ disabled: true });

      expect(findProjectsDropdownFilter().props('disabled')).toBe(true);
    });
  });
});
