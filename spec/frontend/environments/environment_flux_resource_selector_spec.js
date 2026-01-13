import { GlCollapsibleListbox, GlAlert, GlFormGroup, GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { helpPagePath } from '~/helpers/help_page_helper';
import EnvironmentFluxResourceSelector from '~/environments/components/environment_flux_resource_selector.vue';
import { SUPPORTED_HELM_RELEASES, SUPPORTED_KUSTOMIZATIONS } from '~/environments/constants';
import createMockApollo from '../__helpers__/mock_apollo_helper';
import { mockKasTunnelUrl } from './mock_data';

const configuration = {
  basePath: mockKasTunnelUrl.replace(/\/$/, ''),
  baseOptions: {
    headers: {
      'GitLab-Agent-Id': 1,
    },
    withCredentials: true,
  },
};
const namespace = 'my-namespace';

const DEFAULT_PROPS = {
  configuration,
  namespace,
  fluxResourcePath: '',
};

describe('~/environments/components/flux_resource_selector.vue', () => {
  let wrapper;

  const kustomizationItem = {
    apiVersion: 'kustomize.toolkit.fluxcd.io/v1',
    metadata: { name: 'kustomization', namespace },
  };
  const helmReleaseItem = {
    apiVersion: 'helm.toolkit.fluxcd.io/v2beta1',
    metadata: { name: 'helm-release', namespace },
  };

  const getKustomizationsQueryResult = jest.fn().mockReturnValue([kustomizationItem]);

  const getHelmReleasesQueryResult = jest.fn().mockReturnValue([helmReleaseItem]);

  const getDiscoverKustomizationsQueryResult = jest.fn().mockReturnValue({
    preferredVersion: SUPPORTED_KUSTOMIZATIONS[0],
    supportedVersion: SUPPORTED_KUSTOMIZATIONS[0],
  });

  const getDiscoverHelmReleasesQueryResult = jest.fn().mockReturnValue({
    preferredVersion: SUPPORTED_HELM_RELEASES[0],
    supportedVersion: SUPPORTED_HELM_RELEASES[0],
  });

  const createWrapper = ({
    propsData = {},
    kustomizationsQueryResult = null,
    helmReleasesQueryResult = null,
    discoverKustomizationsQueryResult = null,
    discoverHelmReleasesQueryResult = null,
  } = {}) => {
    Vue.use(VueApollo);

    const mockResolvers = {
      Query: {
        fluxKustomizations: kustomizationsQueryResult || getKustomizationsQueryResult,
        fluxHelmReleases: helmReleasesQueryResult || getHelmReleasesQueryResult,
        discoverFluxKustomizations:
          discoverKustomizationsQueryResult || getDiscoverKustomizationsQueryResult,
        discoverFluxHelmReleases:
          discoverHelmReleasesQueryResult || getDiscoverHelmReleasesQueryResult,
      },
    };

    return shallowMountExtended(EnvironmentFluxResourceSelector, {
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      stubs: { GlSprintf },
      apolloProvider: createMockApollo([], mockResolvers),
    });
  };

  const findFluxResourceSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findRequestLink = () => wrapper.findByTestId('request-version-support-link');
  const findDocsLink = () => wrapper.findByTestId('api-docs-link');
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);

  describe('default', () => {
    const kustomizationValue = `${kustomizationItem.apiVersion}/namespaces/${kustomizationItem.metadata.namespace}/kustomizations/${kustomizationItem.metadata.name}`;
    const helmReleaseValue = `${helmReleaseItem.apiVersion}/namespaces/${helmReleaseItem.metadata.namespace}/helmreleases/${helmReleaseItem.metadata.name}`;

    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders flux resource selector', () => {
      expect(findFluxResourceSelector().exists()).toBe(true);
    });

    it('requests the flux resources', async () => {
      await waitForPromises();

      expect(getKustomizationsQueryResult).toHaveBeenCalled();
      expect(getHelmReleasesQueryResult).toHaveBeenCalled();
    });

    it('sets the loading prop while fetching the list', async () => {
      expect(findFluxResourceSelector().props('loading')).toBe(true);

      await waitForPromises();

      expect(findFluxResourceSelector().props('loading')).toBe(false);
    });

    it('renders a list of available flux resources', async () => {
      await waitForPromises();

      expect(findFluxResourceSelector().props('items')).toEqual([
        {
          text: 'Kustomizations',
          options: [{ value: kustomizationValue, text: kustomizationItem.metadata.name }],
        },
        {
          text: 'HelmReleases',
          options: [{ value: helmReleaseValue, text: helmReleaseItem.metadata.name }],
        },
      ]);
    });

    it('renders description', () => {
      expect(findFormGroup().attributes('description')).toBe(
        'If a Flux resource is specified, its reconciliation status is reflected in GitLab.',
      );
    });

    it('filters the flux resources list on user search', async () => {
      await waitForPromises();
      findFluxResourceSelector().vm.$emit('search', 'kustomization');
      await nextTick();

      expect(findFluxResourceSelector().props('items')).toEqual([
        {
          text: 'Kustomizations',
          options: [{ value: kustomizationValue, text: kustomizationItem.metadata.name }],
        },
      ]);
    });

    it('emits changes to the fluxResourcePath', () => {
      findFluxResourceSelector().vm.$emit('select', kustomizationValue);

      expect(wrapper.emitted('change')).toEqual([[kustomizationValue]]);
    });
  });

  describe('when environment has an associated flux resource path', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        propsData: { fluxResourcePath: 'path/to/flux/resource/name/default' },
      });
    });

    it('updates flux resource selector with the name of the associated flux resource', () => {
      expect(findFluxResourceSelector().props('toggleText')).toBe('default');
    });
  });

  describe('when the namespace is not selected', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        propsData: { namespace: '' },
      });
    });

    it('flux resource selector has a disabled state', () => {
      expect(findFluxResourceSelector().props('disabled')).toBe(true);
    });
  });

  describe('when the namespace is selected', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('flux resource selector does not have a disabled state', () => {
      expect(findFluxResourceSelector().props('disabled')).toBe(false);
    });
  });

  describe('on error', () => {
    const error = new Error('Error from the cluster_client API');

    it('renders an alert with both resource types mentioned when both queries failed', async () => {
      wrapper = createWrapper({
        kustomizationsQueryResult: jest.fn().mockRejectedValueOnce(error),
        helmReleasesQueryResult: jest.fn().mockRejectedValueOnce(error),
      });
      await waitForPromises();

      expect(findAlert().text()).toContain(
        'Unable to access the following resources from this environment. Check your authorization on the following and try again',
      );
      expect(findAlert().text()).toContain('Kustomization');
      expect(findAlert().text()).toContain('HelmRelease');
    });

    it('renders an alert with only failed resource type mentioned when one query failed', async () => {
      wrapper = createWrapper({
        kustomizationsQueryResult: jest.fn().mockRejectedValueOnce(error),
      });
      await waitForPromises();

      expect(findAlert().text()).toContain(
        'Unable to access the following resources from this environment. Check your authorization on the following and try again',
      );
      expect(findAlert().text()).toContain('Kustomization');
      expect(findAlert().text()).not.toContain('HelmRelease');
    });
  });

  describe('version discovery', () => {
    it('discovers available versions when namespace is selected', async () => {
      wrapper = createWrapper();
      await waitForPromises();

      expect(getDiscoverKustomizationsQueryResult).toHaveBeenCalled();
      expect(getDiscoverHelmReleasesQueryResult).toHaveBeenCalled();
    });

    it('does not discover versions when namespace is not selected', async () => {
      wrapper = createWrapper({
        propsData: { namespace: '' },
      });
      await waitForPromises();

      expect(getDiscoverKustomizationsQueryResult).not.toHaveBeenCalled();
      expect(getDiscoverHelmReleasesQueryResult).not.toHaveBeenCalled();
    });

    it('uses discovered supported version to fetch resources', async () => {
      wrapper = createWrapper();
      await waitForPromises();

      expect(getKustomizationsQueryResult).toHaveBeenCalledWith(
        expect.anything(),
        { configuration, namespace, version: SUPPORTED_KUSTOMIZATIONS[0] },
        expect.anything(),
        expect.anything(),
      );
      expect(getHelmReleasesQueryResult).toHaveBeenCalledWith(
        expect.anything(),
        { configuration, namespace, version: SUPPORTED_HELM_RELEASES[0] },
        expect.anything(),
        expect.anything(),
      );
    });
  });

  describe('unsupported version warning', () => {
    it('does not show warning when preferred and supported versions match', async () => {
      wrapper = createWrapper();
      await waitForPromises();

      expect(findAlert().exists()).toBe(false);
    });

    it('shows warning when preferred version differs from supported version', async () => {
      wrapper = createWrapper({
        discoverKustomizationsQueryResult: jest.fn().mockReturnValue({
          preferredVersion: 'kustomize.toolkit.fluxcd.io/v999',
          supportedVersion: SUPPORTED_KUSTOMIZATIONS[0],
        }),
      });
      await waitForPromises();

      expect(findAlert().text()).toContain(
        'The preferred version of your resource is not supported',
      );
      expect(findAlert().text()).toContain('kustomize.toolkit.fluxcd.io/v999');
      expect(findAlert().text()).toContain(SUPPORTED_KUSTOMIZATIONS[0]);
    });

    it('shows warning for both resource types when both have unsupported versions', async () => {
      wrapper = createWrapper({
        discoverKustomizationsQueryResult: jest.fn().mockReturnValue({
          preferredVersion: 'kustomize.toolkit.fluxcd.io/v999',
          supportedVersion: SUPPORTED_KUSTOMIZATIONS[0],
        }),
        discoverHelmReleasesQueryResult: jest.fn().mockReturnValue({
          preferredVersion: 'helm.toolkit.fluxcd.io/v999',
          supportedVersion: SUPPORTED_HELM_RELEASES[0],
        }),
      });
      await waitForPromises();

      expect(findAlert().text()).toContain('kustomize.toolkit.fluxcd.io/v999');
      expect(findAlert().text()).toContain('helm.toolkit.fluxcd.io/v999');
    });

    it('shows request version support and API documentation links in warning', async () => {
      wrapper = createWrapper({
        discoverKustomizationsQueryResult: jest.fn().mockReturnValue({
          preferredVersion: 'kustomize.toolkit.fluxcd.io/v999',
          supportedVersion: SUPPORTED_KUSTOMIZATIONS[0],
        }),
      });
      await waitForPromises();

      expect(findAlert().text()).toContain(
        'Request version support or use API to set resource path',
      );

      expect(findRequestLink().props('href')).toBe(
        'https://gitlab.com/gitlab-org/gitlab/-/issues/584823',
      );

      expect(findDocsLink().props('href')).toBe(
        helpPagePath('api/environments.md', { anchor: 'update-an-existing-environment' }),
      );
    });

    it('shows warning when supported version is empty', async () => {
      wrapper = createWrapper({
        discoverKustomizationsQueryResult: jest.fn().mockReturnValue({
          preferredVersion: 'kustomize.toolkit.fluxcd.io/v999',
          supportedVersion: '',
        }),
      });
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain('kustomize.toolkit.fluxcd.io/v999');
      expect(findAlert().text()).not.toContain('available version');
    });

    it('shows both authorization errors and version warnings together', async () => {
      wrapper = createWrapper({
        kustomizationsQueryResult: jest.fn().mockRejectedValueOnce(new Error('Unauthorized')),
        discoverHelmReleasesQueryResult: jest.fn().mockReturnValue({
          preferredVersion: 'helm.toolkit.fluxcd.io/v999',
          supportedVersion: SUPPORTED_HELM_RELEASES[0],
        }),
      });
      await waitForPromises();

      expect(findAlert().text()).toContain('Unable to access the following resources');
      expect(findAlert().text()).toContain('Kustomization');
      expect(findAlert().text()).toContain(
        'The preferred version of your resource is not supported',
      );
      expect(findAlert().text()).toContain('helm.toolkit.fluxcd.io/v999');
    });
  });

  describe('discover error handling', () => {
    it('shows error alert when version discovery fails', async () => {
      wrapper = createWrapper({
        discoverKustomizationsQueryResult: jest
          .fn()
          .mockRejectedValueOnce(new Error('Discovery failed')),
      });
      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain('Unable to discover supported Flux resource versions');
    });

    it('still fetches resources with fallback version when discovery fails', async () => {
      wrapper = createWrapper({
        discoverKustomizationsQueryResult: jest
          .fn()
          .mockRejectedValueOnce(new Error('Discovery failed')),
      });
      await waitForPromises();

      expect(getKustomizationsQueryResult).toHaveBeenCalledWith(
        expect.anything(),
        { configuration, namespace, version: SUPPORTED_KUSTOMIZATIONS[0] },
        expect.anything(),
        expect.anything(),
      );
    });
  });
});
