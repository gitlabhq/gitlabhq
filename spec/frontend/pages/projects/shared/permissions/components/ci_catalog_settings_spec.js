import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlBadge, GlLoadingIcon, GlModal, GlSprintf, GlToggle } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

import catalogResourcesCreate from '~/pages/projects/shared/permissions/graphql/mutations/catalog_resources_create.mutation.graphql';
import getCiCatalogSettingsQuery from '~/pages/projects/shared/permissions/graphql/queries/get_ci_catalog_settings.query.graphql';
import CiCatalogSettings, {
  i18n,
} from '~/pages/projects/shared/permissions/components/ci_catalog_settings.vue';

import { mockCiCatalogSettingsResponse } from './mock_data';

Vue.use(VueApollo);
jest.mock('~/alert');

describe('CiCatalogSettings', () => {
  let wrapper;
  let ciCatalogSettingsResponse;
  let catalogResourcesCreateResponse;

  const fullPath = 'gitlab-org/gitlab';

  const createComponent = ({ ciCatalogSettingsHandler = ciCatalogSettingsResponse } = {}) => {
    const handlers = [
      [getCiCatalogSettingsQuery, ciCatalogSettingsHandler],
      [catalogResourcesCreate, catalogResourcesCreateResponse],
    ];
    const mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(CiCatalogSettings, {
      propsData: {
        fullPath,
      },
      stubs: {
        GlSprintf,
      },
      apolloProvider: mockApollo,
    });

    return waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findModal = () => wrapper.findComponent(GlModal);
  const findToggle = () => wrapper.findComponent(GlToggle);

  const findCiCatalogSettings = () => wrapper.findByTestId('ci-catalog-settings');

  beforeEach(() => {
    ciCatalogSettingsResponse = jest.fn().mockResolvedValue(mockCiCatalogSettingsResponse);
    catalogResourcesCreateResponse = jest.fn();
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

    it('renders the experiment badge', () => {
      expect(findBadge().exists()).toBe(true);
    });

    it('renders the toggle', () => {
      expect(findToggle().exists()).toBe(true);
    });

    it('renders the modal', () => {
      expect(findModal().exists()).toBe(true);
      expect(findModal().attributes('title')).toBe(i18n.modal.title);
    });

    describe('when queries have loaded', () => {
      beforeEach(() => {
        catalogResourcesCreateResponse.mockResolvedValue(mockCiCatalogSettingsResponse);
      });

      it('shows the modal when the toggle is clicked', async () => {
        expect(findModal().props('visible')).toBe(false);

        await findToggle().vm.$emit('change', true);

        expect(findModal().props('visible')).toBe(true);
        expect(findModal().props('actionPrimary').text).toBe(i18n.modal.actionPrimary.text);
      });

      it('hides the modal when cancel is clicked', () => {
        findToggle().vm.$emit('change', true);
        findModal().vm.$emit('canceled');

        expect(findModal().props('visible')).toBe(false);
        expect(catalogResourcesCreateResponse).not.toHaveBeenCalled();
      });

      it('calls the mutation with the correct input from the modal click', async () => {
        expect(catalogResourcesCreateResponse).toHaveBeenCalledTimes(0);

        findToggle().vm.$emit('change', true);
        findModal().vm.$emit('primary');
        await waitForPromises();

        expect(catalogResourcesCreateResponse).toHaveBeenCalledTimes(1);
        expect(catalogResourcesCreateResponse).toHaveBeenCalledWith({
          input: {
            projectPath: fullPath,
          },
        });
      });
    });
  });

  describe('when the query is unsuccessful', () => {
    const failedHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));

    it('throws an error', async () => {
      await createComponent({ ciCatalogSettingsHandler: failedHandler });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({ message: i18n.catalogResourceQueryError });
    });
  });
});
