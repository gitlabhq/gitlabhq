import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlPopover, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import KubernetesStatusBar from '~/environments/components/kubernetes_status_bar.vue';
import {
  CLUSTER_STATUS_HEALTHY_TEXT,
  CLUSTER_STATUS_UNHEALTHY_TEXT,
  SYNC_STATUS_BADGES,
} from '~/environments/constants';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { s__ } from '~/locale';
import { mockKasTunnelUrl } from './mock_data';

Vue.use(VueApollo);

const configuration = {
  basePath: mockKasTunnelUrl.replace(/\/$/, ''),
  baseOptions: {
    headers: { 'GitLab-Agent-Id': '1' },
    withCredentials: true,
  },
};
const environmentName = 'environment_name';

describe('~/environments/components/kubernetes_status_bar.vue', () => {
  let wrapper;

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findHealthBadge = () => wrapper.findByTestId('health-badge');
  const findSyncBadge = () => wrapper.findByTestId('sync-badge');
  const findPopover = () => wrapper.findComponent(GlPopover);

  const fluxKustomizationStatusQuery = jest.fn().mockReturnValue([]);
  const fluxHelmReleaseStatusQuery = jest.fn().mockReturnValue([]);

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        fluxKustomizationStatus: fluxKustomizationStatusQuery,
        fluxHelmReleaseStatus: fluxHelmReleaseStatusQuery,
      },
    };

    return createMockApollo([], mockResolvers);
  };

  const createWrapper = ({
    apolloProvider = createApolloProvider(),
    clusterHealthStatus = '',
    namespace = '',
    fluxResourcePath = '',
  } = {}) => {
    wrapper = shallowMountExtended(KubernetesStatusBar, {
      propsData: {
        clusterHealthStatus,
        configuration,
        environmentName,
        namespace,
        fluxResourcePath,
      },
      apolloProvider,
      stubs: { GlSprintf },
    });
  };

  describe('health badge', () => {
    it('shows loading icon when cluster health is not present', () => {
      createWrapper();

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it.each([
      ['success', 'success', CLUSTER_STATUS_HEALTHY_TEXT],
      ['error', 'danger', CLUSTER_STATUS_UNHEALTHY_TEXT],
    ])(
      'when clusterHealthStatus is %s shows health badge with variant %s and text %s',
      (status, variant, text) => {
        createWrapper({ clusterHealthStatus: status });

        expect(findLoadingIcon().exists()).toBe(false);
        expect(findHealthBadge().props('variant')).toBe(variant);
        expect(findHealthBadge().text()).toBe(text);
      },
    );
  });

  describe('sync badge', () => {
    describe('when no namespace is provided', () => {
      beforeEach(() => {
        createWrapper();
      });

      it("doesn't request Kustomizations and HelmReleases", () => {
        expect(fluxKustomizationStatusQuery).not.toHaveBeenCalled();
        expect(fluxHelmReleaseStatusQuery).not.toHaveBeenCalled();
      });

      it('renders sync status as Unavailable', () => {
        expect(findSyncBadge().text()).toBe(s__('Deployment|Unavailable'));
      });
    });

    describe('when flux resource path is provided', () => {
      const namespace = 'my-namespace';
      let fluxResourcePath;

      describe('if the provided resource is a Kustomization', () => {
        beforeEach(() => {
          fluxResourcePath =
            'kustomize.toolkit.fluxcd.io/v1beta1/namespaces/my-namespace/kustomizations/app';

          createWrapper({ namespace, fluxResourcePath });
        });

        it('requests the Kustomization resource status', () => {
          expect(fluxKustomizationStatusQuery).toHaveBeenCalledWith(
            {},
            expect.objectContaining({
              configuration,
              namespace,
              environmentName,
              fluxResourcePath,
            }),
            expect.any(Object),
            expect.any(Object),
          );
        });

        it("doesn't request HelmRelease resource status", () => {
          expect(fluxHelmReleaseStatusQuery).not.toHaveBeenCalled();
        });
      });

      describe('if the provided resource is a helmRelease', () => {
        beforeEach(() => {
          fluxResourcePath =
            'helm.toolkit.fluxcd.io/v2beta1/namespaces/my-namespace/helmreleases/app';

          createWrapper({ namespace, fluxResourcePath });
        });

        it('requests the HelmRelease resource status', () => {
          expect(fluxHelmReleaseStatusQuery).toHaveBeenCalledWith(
            {},
            expect.objectContaining({
              configuration,
              namespace,
              environmentName,
              fluxResourcePath,
            }),
            expect.any(Object),
            expect.any(Object),
          );
        });

        it("doesn't request Kustomization resource status", () => {
          expect(fluxKustomizationStatusQuery).not.toHaveBeenCalled();
        });
      });
    });

    describe('when namespace is provided', () => {
      describe('with no Flux resources found', () => {
        beforeEach(() => {
          createWrapper({ namespace: 'my-namespace' });
        });

        it('requests Kustomizations', () => {
          expect(fluxKustomizationStatusQuery).toHaveBeenCalled();
        });

        it('requests HelmReleases when there were no Kustomizations found', async () => {
          await waitForPromises();

          expect(fluxHelmReleaseStatusQuery).toHaveBeenCalled();
        });

        it('renders sync status as Unavailable when no Kustomizations and HelmReleases found', async () => {
          await waitForPromises();

          expect(findSyncBadge().text()).toBe(s__('Deployment|Unavailable'));
        });
      });

      describe('with Flux Kustomizations available', () => {
        const createApolloProviderWithKustomizations = ({
          result = { status: 'True', type: 'Ready', message: '' },
        } = {}) => {
          const mockResolvers = {
            Query: {
              fluxKustomizationStatus: jest.fn().mockReturnValue([result]),
              fluxHelmReleaseStatus: fluxHelmReleaseStatusQuery,
            },
          };

          return createMockApollo([], mockResolvers);
        };

        it("doesn't request HelmReleases when the Kustomizations were found", async () => {
          createWrapper({
            apolloProvider: createApolloProviderWithKustomizations(),
            namespace: 'my-namespace',
          });
          await waitForPromises();

          expect(fluxHelmReleaseStatusQuery).not.toHaveBeenCalled();
        });

        it.each`
          status     | type             | badgeType
          ${'True'}  | ${'Stalled'}     | ${'stalled'}
          ${'True'}  | ${'Reconciling'} | ${'reconciling'}
          ${'True'}  | ${'Ready'}       | ${'reconciled'}
          ${'False'} | ${'Ready'}       | ${'failed'}
          ${'True'}  | ${'Unknown'}     | ${'unknown'}
        `(
          'renders $badgeType when status is $status and type is $type',
          async ({ status, type, badgeType }) => {
            createWrapper({
              apolloProvider: createApolloProviderWithKustomizations({
                result: { status, type, message: '' },
              }),
              namespace: 'my-namespace',
            });
            await waitForPromises();

            const badge = SYNC_STATUS_BADGES[badgeType];

            expect(findSyncBadge().text()).toBe(badge.text);
            expect(findSyncBadge().props()).toMatchObject({
              icon: badge.icon,
              variant: badge.variant,
            });
          },
        );

        it.each`
          status     | type             | message             | popoverTitle                                     | popoverText
          ${'True'}  | ${'Stalled'}     | ${'stalled reason'} | ${s__('Deployment|Flux sync stalled')}           | ${'stalled reason'}
          ${'True'}  | ${'Reconciling'} | ${''}               | ${undefined}                                     | ${s__('Deployment|Flux sync reconciling')}
          ${'True'}  | ${'Ready'}       | ${''}               | ${undefined}                                     | ${s__('Deployment|Flux sync reconciled successfully')}
          ${'False'} | ${'Ready'}       | ${'failed reason'}  | ${s__('Deployment|Flux sync failed')}            | ${'failed reason'}
          ${'True'}  | ${'Unknown'}     | ${''}               | ${s__('Deployment|Flux sync status is unknown')} | ${s__('Deployment|Unable to detect state. %{linkStart}How are states detected?%{linkEnd}')}
        `(
          'renders correct popover text when status is $status and type is $type',
          async ({ status, type, message, popoverTitle, popoverText }) => {
            createWrapper({
              apolloProvider: createApolloProviderWithKustomizations({
                result: { status, type, message },
              }),
              namespace: 'my-namespace',
            });
            await waitForPromises();

            expect(findPopover().text()).toMatchInterpolatedText(popoverText);
            expect(findPopover().props('title')).toBe(popoverTitle);
          },
        );
      });

      describe('when Flux API errored', () => {
        const error = new Error('Error from the cluster_client API');
        const createApolloProviderWithErrors = () => {
          const mockResolvers = {
            Query: {
              fluxKustomizationStatus: jest.fn().mockRejectedValueOnce(error),
              fluxHelmReleaseStatus: jest.fn().mockRejectedValueOnce(error),
            },
          };

          return createMockApollo([], mockResolvers);
        };

        beforeEach(async () => {
          createWrapper({
            apolloProvider: createApolloProviderWithErrors(),
            namespace: 'my-namespace',
          });
          await waitForPromises();
        });

        it('renders sync badge as unavailable', () => {
          const badge = SYNC_STATUS_BADGES.unavailable;

          expect(findSyncBadge().text()).toBe(badge.text);
          expect(findSyncBadge().props()).toMatchObject({
            icon: badge.icon,
            variant: badge.variant,
          });
        });

        it('renders popover with an API error message', () => {
          expect(findPopover().text()).toBe(error.message);
          expect(findPopover().props('title')).toBe(
            s__('Deployment|Flux sync status is unavailable'),
          );
        });
      });
    });
  });
});
