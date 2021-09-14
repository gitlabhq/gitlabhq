import { GlSearchBoxByType, GlAvatarLabeled, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as projectsApi from '~/api/projects_api';
import ProjectSelect from '~/invite_members/components/project_select.vue';
import { allProjects, project1 } from '../mock_data/api_response_data';

describe('ProjectSelect', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ProjectSelect, {});
  };

  beforeEach(() => {
    jest.spyOn(projectsApi, 'getProjects').mockResolvedValue(allProjects);

    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findSearchBoxByType = () => wrapper.findComponent(GlSearchBoxByType);
  const findDropdownItem = (index) => wrapper.findAllComponents(GlDropdownItem).at(index);
  const findAvatarLabeled = (index) => findDropdownItem(index).findComponent(GlAvatarLabeled);
  const findEmptyResultMessage = () => wrapper.findByTestId('empty-result-message');
  const findErrorMessage = () => wrapper.findByTestId('error-message');

  it('renders GlSearchBoxByType with default attributes', () => {
    expect(findSearchBoxByType().exists()).toBe(true);
    expect(findSearchBoxByType().vm.$attrs).toMatchObject({
      placeholder: 'Search projects',
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

      findSearchBoxByType().vm.$emit('input', project1.name);
    });

    it('calls the API', () => {
      resolveApiRequest({ data: allProjects });

      expect(projectsApi.getProjects).toHaveBeenCalledWith(project1.name, {
        active: true,
        exclude_internal: true,
      });
    });

    it('displays loading icon while waiting for API call to resolve and then sets loading false', async () => {
      expect(findSearchBoxByType().props('isLoading')).toBe(true);

      resolveApiRequest({ data: allProjects });
      await waitForPromises();

      expect(findSearchBoxByType().props('isLoading')).toBe(false);
      expect(findEmptyResultMessage().exists()).toBe(false);
      expect(findErrorMessage().exists()).toBe(false);
    });

    it('displays a dropdown item and avatar for each project fetched', async () => {
      resolveApiRequest({ data: allProjects });
      await waitForPromises();

      allProjects.forEach((project, index) => {
        expect(findDropdownItem(index).attributes('name')).toBe(project.name_with_namespace);
        expect(findAvatarLabeled(index).attributes()).toMatchObject({
          src: project.avatar_url,
          'entity-id': String(project.id),
          'entity-name': project.name_with_namespace,
        });
        expect(findAvatarLabeled(index).props('label')).toBe(project.name_with_namespace);
      });
    });

    it('displays the empty message when the API results are empty', async () => {
      resolveApiRequest({ data: [] });
      await waitForPromises();

      expect(findEmptyResultMessage().text()).toBe('No matching results');
    });

    it('displays the error message when the fetch fails', async () => {
      rejectApiRequest();
      await waitForPromises();

      expect(findErrorMessage().text()).toBe(
        'There was an error fetching the projects. Please try again.',
      );
    });
  });
});
