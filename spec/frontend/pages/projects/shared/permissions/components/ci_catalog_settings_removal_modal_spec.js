import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import getCiCatalogResourceUsageQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_usage.query.graphql';
import CiCatalogSettingsRemovalModal from '~/pages/projects/shared/permissions/components/ci_catalog_settings_removal_modal.vue';
import { generateCatalogResourceUsageResponse } from './mock_data';

Vue.use(VueApollo);

describe('CiCatalogSettingsRemovalModal', () => {
  let wrapper;
  let ciCatalogResourceUsageResponse;

  const fullPath = 'gitlab-org/gitlab';

  const createComponent = () => {
    const mockApollo = createMockApollo([
      [getCiCatalogResourceUsageQuery, ciCatalogResourceUsageResponse],
    ]);

    wrapper = shallowMountExtended(CiCatalogSettingsRemovalModal, {
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

  const findModal = () => wrapper.findComponent(GlModal);
  const findRemovalDetails = () => wrapper.findByTestId('removal-details');

  beforeEach(() => {
    ciCatalogResourceUsageResponse = jest
      .fn()
      .mockResolvedValue(generateCatalogResourceUsageResponse(0));
  });

  it('renders a visible modal', async () => {
    await createComponent();

    expect(findModal().props('visible')).toBe(true);
    expect(findModal().props('actionPrimary').text).toBe('Remove from the CI/CD catalog');
  });

  it('fetches the usage count for the project', async () => {
    await createComponent();

    expect(ciCatalogResourceUsageResponse).toHaveBeenCalledWith({ fullPath });
  });

  it('emits close when the modal is hidden', async () => {
    await createComponent();

    findModal().vm.$emit('hidden');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('emits primary when the removal is confirmed', async () => {
    await createComponent();

    findModal().vm.$emit('primary');

    expect(wrapper.emitted('primary')).toHaveLength(1);
  });

  it.each`
    count   | expected
    ${0}    | ${'This component is used in 0 projects.'}
    ${1}    | ${'This component is used in 1 project.'}
    ${1234} | ${'This component is used in 1,234 projects.'}
  `('renders "$expected" for a count of $count', async ({ count, expected }) => {
    ciCatalogResourceUsageResponse.mockResolvedValue(generateCatalogResourceUsageResponse(count));

    await createComponent();

    expect(findRemovalDetails().text()).toContain(expected);
  });

  it('renders removal details', async () => {
    ciCatalogResourceUsageResponse.mockResolvedValue(generateCatalogResourceUsageResponse(3));

    await createComponent();

    expect(findRemovalDetails().text()).toContain(
      'The project and any released versions will be removed from the CI/CD Catalog.',
    );
  });

  describe('when the usage count cannot be read', () => {
    beforeEach(async () => {
      ciCatalogResourceUsageResponse.mockRejectedValue(new Error('unpublished'));

      await createComponent();
    });

    it('renders removal details', () => {
      expect(findRemovalDetails().text()).toBe(
        'The project and any released versions will be removed from the CI/CD Catalog.',
      );
    });
  });
});
