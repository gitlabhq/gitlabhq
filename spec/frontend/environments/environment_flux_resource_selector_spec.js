import { GlCollapsibleListbox, GlAlert, GlFormGroup } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import EnvironmentFluxResourceSelector from '~/environments/components/environment_flux_resource_selector.vue';
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

  const createWrapper = ({
    propsData = {},
    kustomizationsQueryResult = null,
    helmReleasesQueryResult = null,
  } = {}) => {
    Vue.use(VueApollo);

    const mockResolvers = {
      Query: {
        fluxKustomizations: kustomizationsQueryResult || getKustomizationsQueryResult,
        fluxHelmReleases: helmReleasesQueryResult || getHelmReleasesQueryResult,
      },
    };

    return shallowMount(EnvironmentFluxResourceSelector, {
      propsData: {
        ...DEFAULT_PROPS,
        ...propsData,
      },
      apolloProvider: createMockApollo([], mockResolvers),
    });
  };

  const findFluxResourceSelector = () => wrapper.findComponent(GlCollapsibleListbox);
  const findAlert = () => wrapper.findComponent(GlAlert);
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
});
