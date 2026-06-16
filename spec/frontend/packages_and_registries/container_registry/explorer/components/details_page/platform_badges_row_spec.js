import { GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { NO_PLATFORMS_AVAILABLE_TEXT } from '~/packages_and_registries/container_registry/explorer/constants/index';
import PlatformBadgesRow from '~/packages_and_registries/container_registry/explorer/components/details_page/platform_badges_row.vue';
import PlatformBadge from '~/packages_and_registries/container_registry/explorer/components/details_page/platform_badge.vue';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import getTagPlatformDetailsQuery from '~/packages_and_registries/container_registry/explorer/graphql/queries/get_tag_platform_details.query.graphql';
import { tagsMock, tagDetailsManifestedMock, graphQLTagDetailsMock } from '../../mock_data';

Vue.use(VueApollo);

describe('platform badges row', () => {
  let wrapper;
  const tag = tagsMock[0];

  const defaultTagDetailsHandler = jest.fn().mockResolvedValue(graphQLTagDetailsMock());

  const mountComponent = (
    propsData = { tag },
    { tagDetailsHandler = defaultTagDetailsHandler } = {},
  ) => {
    wrapper = shallowMountExtended(PlatformBadgesRow, {
      stubs: { GlSprintf, DetailsRow },
      propsData,
      apolloProvider: createMockApollo([[getTagPlatformDetailsQuery, tagDetailsHandler]]),
      mocks: { $route: { params: { id: 123 } } },
    });
  };

  const findSupportedPlatforms = () => wrapper.findByTestId('manifest-platforms');
  const findNoPlatformsMessage = () => wrapper.findByTestId('no-platforms-available');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPlatformBadges = () => wrapper.findAllComponents(PlatformBadge);

  it('renders the supported platforms row', () => {
    mountComponent();

    expect(findSupportedPlatforms().exists()).toBe(true);
  });

  it('shows loading icon before query resolves', async () => {
    mountComponent();
    await nextTick();

    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('hides loading icon after query resolves', async () => {
    mountComponent();
    await waitForPromises();

    expect(findLoadingIcon().exists()).toBe(false);
  });

  it('renders platform badges after query resolves', async () => {
    mountComponent();
    await waitForPromises();

    expect(findPlatformBadges()).toHaveLength(tagDetailsManifestedMock.manifests.length);
  });

  it('passes correct platform prop to each badge', async () => {
    mountComponent();
    await waitForPromises();

    tagDetailsManifestedMock.manifests.forEach((manifest, index) => {
      expect(findPlatformBadges().at(index).props('platform')).toEqual(manifest.platform);
    });
  });

  it('calls query with correct variables', async () => {
    mountComponent();
    await waitForPromises();

    expect(defaultTagDetailsHandler).toHaveBeenCalledWith({
      id: 'gid://gitlab/ContainerRepository/123',
      tagName: tag.name,
    });
  });

  it('sorts manifests by os, architecture, variant, osVersion before rendering', async () => {
    const handler = jest.fn().mockResolvedValue(
      graphQLTagDetailsMock({
        manifests: [
          {
            digest: 'sha256:s1',
            platform: {
              os: 'windows',
              architecture: 'amd64',
              variant: null,
              osVersion: '10.0.2034.0',
            },
          },
          {
            digest: 'sha256:s2',
            platform: { os: 'linux', architecture: 'arm64', variant: 'v8', osVersion: null },
          },
          {
            digest: 'sha256:s3',
            platform: { os: 'linux', architecture: 'amd64', variant: null, osVersion: null },
          },
          {
            digest: 'sha256:s4',
            platform: { os: 'linux', architecture: 'arm64', variant: 'v6', osVersion: null },
          },
          {
            digest: 'sha256:s5',
            platform: {
              os: 'windows',
              architecture: 'amd64',
              variant: null,
              osVersion: '10.0.17763.0',
            },
          },
        ],
      }),
    );
    mountComponent({ tag }, { tagDetailsHandler: handler });
    await waitForPromises();

    expect(wrapper.vm.tagManifests.map((m) => m.platform)).toEqual([
      { os: 'linux', architecture: 'amd64', variant: null, osVersion: null },
      { os: 'linux', architecture: 'arm64', variant: 'v6', osVersion: null },
      { os: 'linux', architecture: 'arm64', variant: 'v8', osVersion: null },
      // Sorting of osVersion is done lexicalgraphically, which may need to be revisited in the future
      { os: 'windows', architecture: 'amd64', variant: null, osVersion: '10.0.17763.0' },
      { os: 'windows', architecture: 'amd64', variant: null, osVersion: '10.0.2034.0' },
    ]);
  });

  it('ignores manifests with no platform', async () => {
    const handler = jest.fn().mockResolvedValue(
      graphQLTagDetailsMock({
        manifests: [
          {
            digest: 'sha256:s1',
            platform: { os: 'linux', architecture: 'arm64', variant: 'v8', osVersion: null },
          },
          {
            digest: 'sha256:s2',
            platform: { os: 'linux', architecture: 'amd64', variant: null, osVersion: null },
          },
          {
            digest: 'sha256:s3',
            platform: null,
          },
          {
            digest: 'sha256:s4',
            platform: { os: '', architecture: 'amd64', variant: null, osVersion: null },
          },
          {
            digest: 'sha256:s5',
            platform: { os: 'linux', architecture: '', variant: null, osVersion: null },
          },
        ],
      }),
    );
    mountComponent({ tag }, { tagDetailsHandler: handler });
    await waitForPromises();

    expect(wrapper.vm.tagManifests.map((m) => m.platform)).toEqual([
      { os: 'linux', architecture: 'amd64', variant: null, osVersion: null },
      { os: 'linux', architecture: 'arm64', variant: 'v8', osVersion: null },
    ]);
  });

  it('renders no badges when tagDetails has no manifests', async () => {
    const emptyHandler = jest.fn().mockResolvedValue(graphQLTagDetailsMock({ manifests: [] }));
    mountComponent({ tag }, { tagDetailsHandler: emptyHandler });
    await waitForPromises();

    expect(findPlatformBadges()).toHaveLength(0);
    expect(findNoPlatformsMessage().text()).toBe(NO_PLATFORMS_AVAILABLE_TEXT);
  });

  it('renders no badges when the query errors', async () => {
    const errorHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
    mountComponent({ tag }, { tagDetailsHandler: errorHandler });
    await waitForPromises();

    expect(findPlatformBadges()).toHaveLength(0);
  });
});
