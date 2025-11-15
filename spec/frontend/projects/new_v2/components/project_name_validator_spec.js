import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectNameValidator from '~/projects/new_v2/components/project_name_validator.vue';
import { DEBOUNCE_DELAY } from '~/vue_shared/components/filtered_search_bar/constants';
import searchProjectNameAvailabilityQuery from '~/projects/new_v2/queries/search_project_name_availability.query.graphql';

Vue.use(VueApollo);

describe('Project name availability alert', () => {
  let wrapper;

  const defaultHandler = [
    searchProjectNameAvailabilityQuery,
    jest.fn().mockResolvedValue({
      data: {
        namespace: {
          id: 'gid://gitlab/Group/1',
          projects: {
            nodes: [
              {
                id: '1',
                name: 'Test 1',
                path: 'test-1',
              },
              {
                id: '2',
                name: 'Test 2',
                path: 'test-2',
              },
            ],
          },
        },
      },
    }),
  ];

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ProjectNameValidator, {
      apolloProvider: createMockApollo([defaultHandler]),
      propsData: {
        namespaceFullPath: 'namespace-full-path',
        ...props,
      },
    });

    return waitForPromises();
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  const waitForQuery = async () => {
    jest.advanceTimersByTime(DEBOUNCE_DELAY);
    await waitForPromises();
  };

  it('does not render an alert if project name and path are not defined', () => {
    createComponent();

    expect(findAlert().exists()).toBe(false);
  });

  describe('renders an alert', () => {
    it('when name exists', async () => {
      await createComponent({ projectName: 'Test 1' });
      await waitForQuery();

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain('name');
      expect(findAlert().text()).not.toContain('path');
    });

    it('when path exists', async () => {
      await createComponent({ projectPath: 'test-2' });
      await waitForQuery();

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain('path');
      expect(findAlert().text()).not.toContain('name');
    });

    it('when both path and exist', async () => {
      await createComponent({ projectName: 'Test 1', projectPath: 'test-1' });
      await waitForQuery();

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain('path');
      expect(findAlert().text()).toContain('name');
    });
  });

  describe('when namespace path is missing', () => {
    it('query does not run', async () => {
      const mockHandler = jest.fn();
      wrapper = shallowMountExtended(ProjectNameValidator, {
        apolloProvider: createMockApollo([[searchProjectNameAvailabilityQuery, mockHandler]]),
        propsData: {
          namespaceFullPath: null,
          projectName: 'Test Project',
          projectPath: 'test-project',
        },
      });

      await waitForQuery();

      expect(mockHandler).not.toHaveBeenCalled();
      expect(findAlert().exists()).toBe(false);
    });
  });
});
