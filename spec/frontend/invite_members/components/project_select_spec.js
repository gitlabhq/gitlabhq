import { GlAvatarLabeled, GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as projectsApi from '~/api/projects_api';
import ProjectSelect from '~/invite_members/components/project_select.vue';
import { allProjects, project1 } from '../mock_data/api_response_data';

describe('ProjectSelect', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ProjectSelect, {
      stubs: {
        GlCollapsibleListbox,
        GlAvatarLabeled,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(projectsApi, 'getProjects').mockResolvedValue(allProjects);

    createComponent();
  });

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAvatarLabeled = (index) => wrapper.findAllComponents(GlAvatarLabeled).at(index);

  it('renders GlCollapsibleListbox with default props', () => {
    expect(findGlCollapsibleListbox().exists()).toBe(true);
    expect(findGlCollapsibleListbox().props()).toMatchObject({
      items: [],
      loading: false,
      multiple: false,
      noResultsText: 'No matching results',
      placement: 'bottom-start',
      searchPlaceholder: 'Search projects',
      searchable: true,
      searching: false,
      size: 'medium',
      toggleText: 'Select a project',
      totalItems: null,
      variant: 'default',
    });
  });

  describe('when user types in the search input', () => {
    let resolveApiRequest;
    let rejectApiRequest;

    beforeEach(() => {
      jest.spyOn(projectsApi, 'getProjects').mockImplementation(
        () =>
          new Promise((resolve, reject) => {
            resolveApiRequest = resolve;
            rejectApiRequest = reject;
          }),
      );

      findGlCollapsibleListbox().vm.$emit('search', project1.name);
    });

    it('calls the API', () => {
      resolveApiRequest({ data: allProjects });

      expect(projectsApi.getProjects).toHaveBeenCalledWith(project1.name, {
        active: true,
        exclude_internal: true,
      });
    });

    it('displays loading icon while waiting for API call to resolve and then sets loading false', async () => {
      expect(findGlCollapsibleListbox().props('searching')).toBe(true);

      resolveApiRequest({ data: allProjects });
      await waitForPromises();

      expect(findGlCollapsibleListbox().props('searching')).toBe(false);
    });

    it('displays a dropdown item and avatar for each project fetched', async () => {
      resolveApiRequest({ data: allProjects });
      await waitForPromises();

      allProjects.forEach((project, index) => {
        expect(findAvatarLabeled(index).attributes()).toMatchObject({
          src: project.avatar_url,
          'entity-id': String(project.id),
          'entity-name': project.name_with_namespace,
          size: '32',
        });
        expect(findAvatarLabeled(index).props('label')).toBe(project.name_with_namespace);
      });
    });

    it('displays the empty message when the API results are empty', async () => {
      resolveApiRequest({ data: [] });
      await waitForPromises();

      expect(findGlCollapsibleListbox().text()).toBe('No matching results');
    });

    it('displays the error message when the fetch fails', async () => {
      rejectApiRequest();
      await waitForPromises();

      // To be displayed in GlCollapsibleListbox once we implement
      // https://gitlab.com/gitlab-org/gitlab-ui/-/issues/2132
      // https://gitlab.com/gitlab-org/gitlab/-/issues/389974
      expect(findGlCollapsibleListbox().text()).toBe('No matching results');
    });
  });
});
