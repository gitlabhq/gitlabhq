import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlModal, GlSprintf, GlToggle } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import catalogResourcesCreate from '~/ci/catalog/graphql/mutations/catalog_resources_create.mutation.graphql';
import catalogResourcesDestroy from '~/ci/catalog/graphql/mutations/catalog_resources_destroy.mutation.graphql';
import getCiCatalogSettingsQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_settings.query.graphql';
import CiCatalogSettings from '~/pages/projects/shared/permissions/components/ci_catalog_settings.vue';

import { generateCatalogSettingsResponse } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

const showToast = jest.fn();

describe('CiCatalogSettings', () => {
  let wrapper;
  let ciCatalogSettingsResponse;
  let catalogResourcesCreateResponse;
  let catalogResourcesDestroyResponse;

  const fullPath = 'gitlab-org/gitlab';

  const createComponent = ({ ciCatalogSettingsHandler = ciCatalogSettingsResponse } = {}) => {
    const handlers = [
      [getCiCatalogSettingsQuery, ciCatalogSettingsHandler],
      [catalogResourcesCreate, catalogResourcesCreateResponse],
      [catalogResourcesDestroy, catalogResourcesDestroyResponse],
    ];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(CiCatalogSettings, {
      propsData: {
        fullPath,
      },
      stubs: {
        GlSprintf,
      },
      mocks: {
        $toast: {
          show: showToast,
        },
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findModal = () => wrapper.findComponent(GlModal);
  const findToggle = () => wrapper.findComponent(GlToggle);
  const findCiCatalogSettings = () => wrapper.findByTestId('ci-catalog-settings');

  const removeCatalogResource = () => {
    findToggle().vm.$emit('change');
    findModal().vm.$emit('primary');
    return waitForPromises();
  };

  const setCatalogResource = () => {
    findToggle().vm.$emit('change');
    return waitForPromises();
  };

  beforeEach(() => {
    ciCatalogSettingsResponse = jest.fn();
    catalogResourcesDestroyResponse = jest.fn();
    catalogResourcesCreateResponse = jest.fn();

    ciCatalogSettingsResponse.mockResolvedValue(generateCatalogSettingsResponse());
    catalogResourcesCreateResponse.mockResolvedValue({
      data: { catalogResourcesCreate: { errors: [] } },
    });
    catalogResourcesDestroyResponse.mockResolvedValue({
      data: { catalogResourcesDestroy: { errors: [] } },
    });
  });

  describe('when initial queries are loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a loading icon and no CI catalog settings', () => {
      expect(findLoadingIcon().exists()).toBe(true);
      expect(findCiCatalogSettings().exists()).toBe(false);
    });
  });

  describe('when queries have loaded', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('does not show a loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the CI Catalog settings', () => {
      expect(findCiCatalogSettings().exists()).toBe(true);
    });

    it('renders the toggle', () => {
      expect(findToggle().exists()).toBe(true);
    });
  });

  describe('when the project is not a CI/CD resource', () => {
    beforeEach(async () => {
      await createComponent();
    });

    describe('and the toggle is clicked', () => {
      it('does not show a confirmation modal', async () => {
        expect(findModal().props('visible')).toBe(false);

        await findToggle().vm.$emit('change', true);

        expect(findModal().props('visible')).toBe(false);
      });

      it('calls the mutation with the correct input', async () => {
        expect(catalogResourcesCreateResponse).toHaveBeenCalledTimes(0);

        await setCatalogResource();

        expect(catalogResourcesCreateResponse).toHaveBeenCalledTimes(1);
        expect(catalogResourcesCreateResponse).toHaveBeenCalledWith({
          input: {
            projectPath: fullPath,
          },
        });
      });

      describe('when the mutation is successful', () => {
        it('shows a toast message with a success message', async () => {
          expect(showToast).not.toHaveBeenCalled();

          await setCatalogResource();

          expect(showToast).toHaveBeenCalledWith('This project is now a CI/CD Catalog project.');
        });
      });
    });
  });

  describe('when the project is a CI/CD resource', () => {
    beforeEach(async () => {
      ciCatalogSettingsResponse.mockResolvedValue(generateCatalogSettingsResponse(true));
      await createComponent();
    });

    describe('and the toggle is clicked', () => {
      it('shows a confirmation modal', async () => {
        expect(findModal().props('visible')).toBe(false);

        await findToggle().vm.$emit('change', false);

        expect(findModal().props('visible')).toBe(true);
        expect(findModal().props('actionPrimary').text).toBe('Remove from the CI/CD catalog');
      });

      it('hides the modal when cancel is clicked', () => {
        findToggle().vm.$emit('change', true);
        findModal().vm.$emit('canceled');

        expect(findModal().props('visible')).toBe(false);
        expect(catalogResourcesCreateResponse).not.toHaveBeenCalled();
      });

      it('calls the mutation with the correct input from the modal click', async () => {
        expect(catalogResourcesDestroyResponse).toHaveBeenCalledTimes(0);

        await removeCatalogResource();

        expect(catalogResourcesDestroyResponse).toHaveBeenCalledTimes(1);
        expect(catalogResourcesDestroyResponse).toHaveBeenCalledWith({
          input: {
            projectPath: fullPath,
          },
        });
      });

      it('shows a toast message when the mutation has worked', async () => {
        expect(showToast).not.toHaveBeenCalled();

        await removeCatalogResource();

        expect(showToast).toHaveBeenCalledWith(
          'This project is no longer a CI/CD Catalog project.',
        );
      });
    });
  });

  describe('mutation errors', () => {
    const createGraphqlError = { data: { catalogResourcesCreate: { errors: ['graphql error'] } } };
    const destroyGraphqlError = {
      data: { catalogResourcesDestroy: { errors: ['graphql error'] } },
    };

    beforeEach(() => {
      createAlert.mockClear();
    });

    it.each`
      name         | errorType                                     | jestResolver           | mockResponse                 | expectedMessage
      ${'create'}  | ${'unhandled server error with a message'}    | ${'mockRejectedValue'} | ${new Error('server error')} | ${'server error'}
      ${'create'}  | ${'unhandled server error without a message'} | ${'mockRejectedValue'} | ${new Error()}               | ${'Unable to set project as a CI/CD Catalog project.'}
      ${'create'}  | ${'handled Graphql error'}                    | ${'mockResolvedValue'} | ${createGraphqlError}        | ${'graphql error'}
      ${'destroy'} | ${'unhandled server'}                         | ${'mockRejectedValue'} | ${new Error('server error')} | ${'server error'}
      ${'destroy'} | ${'unhandled server'}                         | ${'mockRejectedValue'} | ${new Error()}               | ${'Unable to remove project as a CI/CD Catalog project.'}
      ${'destroy'} | ${'handled Graphql error'}                    | ${'mockResolvedValue'} | ${destroyGraphqlError}       | ${'graphql error'}
    `(
      'when $name mutation returns an $errorType',
      async ({ name, jestResolver, mockResponse, expectedMessage }) => {
        let mutationMock = catalogResourcesCreateResponse;
        let toggleAction = setCatalogResource;

        if (name === 'destroy') {
          mutationMock = catalogResourcesDestroyResponse;
          toggleAction = removeCatalogResource;
          ciCatalogSettingsResponse.mockResolvedValue(generateCatalogSettingsResponse(true));
        }

        await createComponent();
        mutationMock[jestResolver](mockResponse);

        expect(showToast).not.toHaveBeenCalled();
        expect(createAlert).not.toHaveBeenCalled();

        await toggleAction();

        expect(showToast).not.toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({ message: expectedMessage });
      },
    );
  });

  describe('when the query is unsuccessful', () => {
    beforeEach(async () => {
      const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
      await createComponent({ ciCatalogSettingsHandler: failedHandler });
      await waitForPromises();
    });

    it('throws an error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was a problem fetching the CI/CD Catalog setting.',
      });
    });
  });
});
