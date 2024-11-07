import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon, GlAlert, GlEmptyState, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import KubernetesLogs from '~/environments/environment_details/components/kubernetes/kubernetes_logs.vue';
import environmentClusterAgentQuery from '~/environments/graphql/queries/environment_cluster_agent.query.graphql';
import LogsViewer from '~/vue_shared/components/logs_viewer/logs_viewer.vue';
import { createK8sAccessConfiguration } from '~/environments/helpers/k8s_integration_helper';
import { mockKasTunnelUrl } from '../../../mock_data';
import { agent, kubernetesNamespace, fluxResourcePathMock } from '../../../graphql/mock_data';

Vue.use(VueApollo);

describe('kubernetes_logs', () => {
  let wrapper;

  const defaultProps = {
    podName: 'test-pod',
    namespace: kubernetesNamespace,
    environmentName: 'test-environment',
    highlightedLineHash: 'L2',
  };

  const kasTunnelUrl = mockKasTunnelUrl;
  const projectPath = 'gitlab-org/test-project';
  const gitlabAgentId = '1';

  const configuration = createK8sAccessConfiguration({
    kasTunnelUrl,
    gitlabAgentId,
  });
  let k8sLogsQueryMock;
  let abortK8sPodLogsStreamMock;
  let environmentDataMock;

  const defaultEnvironmentData = {
    data: {
      project: {
        id: '1',
        environment: {
          id: '1',
          clusterAgent: agent,
          kubernetesNamespace,
          fluxResourcePath: fluxResourcePathMock,
          deploymentsDisplayCount: 3,
        },
      },
    },
  };

  const logsMockData = [
    {
      content: 'first log line content',
      id: 1,
    },
    {
      content: 'second log line content',
      id: 2,
    },
  ];
  const setUpMocks = () => {
    k8sLogsQueryMock = jest.fn().mockResolvedValue({
      logs: logsMockData,
    });
    abortK8sPodLogsStreamMock = jest.fn().mockResolvedValue({ errors: [] });
    environmentDataMock = jest.fn().mockResolvedValue(defaultEnvironmentData);
  };

  const createApolloProvider = () => {
    const mockResolvers = {
      Query: {
        k8sLogs: k8sLogsQueryMock,
      },
      Mutation: {
        abortK8sPodLogsStream: abortK8sPodLogsStreamMock,
      },
    };

    return createMockApollo([[environmentClusterAgentQuery, environmentDataMock]], mockResolvers);
  };

  const mountComponent = (props) => {
    const propsData = { ...defaultProps, ...props };
    const apolloProvider = createApolloProvider();
    wrapper = shallowMount(KubernetesLogs, {
      propsData,
      provide: {
        kasTunnelUrl,
        projectPath,
      },
      apolloProvider,
      stubs: { GlSprintf },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLogsViewer = () => wrapper.findComponent(LogsViewer);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    setUpMocks();
  });

  describe('when environment data is not ready', () => {
    beforeEach(() => {
      mountComponent();
    });
    it('should not query logs', () => {
      expect(k8sLogsQueryMock).not.toHaveBeenCalled();
    });
    it('should render loading state', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
    it('should not render empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when failed to fetch data', () => {
    const error = new Error('Error from the environment query');
    beforeEach(async () => {
      environmentDataMock.mockRejectedValue(error);
      mountComponent();
      await waitForPromises();
    });
    it('should not query logs', () => {
      expect(k8sLogsQueryMock).not.toHaveBeenCalled();
    });
    it('should not render loading state', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });
    it('should render error state', () => {
      expect(findAlert().text()).toBe(`Error: ${error.message}`);
    });
    it('should render empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('when environment data is ready', () => {
    describe('when no container is specified for the logs', () => {
      describe('when logs data is empty', () => {
        beforeEach(async () => {
          k8sLogsQueryMock = jest.fn().mockResolvedValue({});
          mountComponent();
          await waitForPromises();
        });

        it('should not render loading state', () => {
          expect(findLoadingIcon().exists()).toBe(false);
        });
        it('should not render error state', () => {
          expect(findAlert().exists()).toBe(false);
        });
        it('should not render logs viewer', () => {
          expect(findLogsViewer().exists()).toBe(false);
        });
        it('should render empty state with pod name', () => {
          expect(findEmptyState().text()).toBe('No logs available for pod test-pod');
        });
      });

      describe('when logs data fetched successfully', () => {
        beforeEach(async () => {
          mountComponent();
          await waitForPromises();
        });

        it('should not render loading state', () => {
          expect(findLoadingIcon().exists()).toBe(false);
        });
        it('should not render error state', () => {
          expect(findAlert().exists()).toBe(false);
        });
        it('should not render empty state', () => {
          expect(findEmptyState().exists()).toBe(false);
        });

        it('should query logs', () => {
          expect(k8sLogsQueryMock).toHaveBeenCalledWith(
            expect.anything(),
            {
              configuration,
              namespace: defaultProps.namespace,
              podName: defaultProps.podName,
              containerName: '',
            },
            expect.anything(),
            expect.anything(),
          );
        });
        it('should render logs viewer component with correct parameters', () => {
          const expectedLogLines = [
            {
              content: [{ text: logsMockData[0].content }],
              lineNumber: 1,
              lineId: 'L1',
            },
            {
              content: [{ text: logsMockData[1].content }],
              lineNumber: 2,
              lineId: 'L2',
            },
          ];
          expect(findLogsViewer().props()).toMatchObject({
            logLines: expectedLogLines,
            highlightedLine: 'L2',
          });
        });
        it('should provide correct header details to the logs viewer', () => {
          expect(findLogsViewer().text()).toBe(
            `Agent ID: ${gitlabAgentId}Namespace: ${kubernetesNamespace}Pod: ${defaultProps.podName}`,
          );
        });
      });

      describe('when logs data fetch failed', () => {
        const errorMessage = 'Error while fetching logs';

        beforeEach(async () => {
          k8sLogsQueryMock = jest.fn().mockResolvedValue({
            error: { message: errorMessage },
          });
          mountComponent();
          await waitForPromises();
        });

        it('should not render loading state', () => {
          expect(findLoadingIcon().exists()).toBe(false);
        });
        it('should render error state', () => {
          expect(findAlert().text()).toBe(`Error: ${errorMessage}`);
        });
        it('should render empty state', () => {
          expect(findEmptyState().exists()).toBe(true);
        });
        it('should not render logs viewer', () => {
          expect(findLogsViewer().exists()).toBe(false);
        });
      });
    });
    describe('when a container is specified for the logs', () => {
      it('should render empty state with pod and container name when log data is empty', async () => {
        k8sLogsQueryMock = jest.fn().mockResolvedValue({});
        mountComponent({ containerName: 'my-container' });
        await waitForPromises();

        expect(findEmptyState().text()).toBe(
          'No logs available for container my-container of pod test-pod',
        );
      });

      it('should query logs with the container name included', async () => {
        mountComponent({ containerName: 'my-container' });
        await waitForPromises();

        expect(k8sLogsQueryMock).toHaveBeenCalledWith(
          expect.anything(),
          {
            configuration,
            namespace: defaultProps.namespace,
            podName: defaultProps.podName,
            containerName: 'my-container',
          },
          expect.anything(),
          expect.anything(),
        );
      });

      it('should provide correct header details to the logs viewer', async () => {
        mountComponent({ containerName: 'my-container' });
        await waitForPromises();

        expect(findLogsViewer().text()).toBe(
          `Agent ID: ${gitlabAgentId}Namespace: ${kubernetesNamespace}Pod: ${defaultProps.podName}Container: my-container`,
        );
      });
    });
  });

  describe('beforeDestroy', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
      wrapper.destroy();
    });

    it('triggers `abortPodLogsStream` mutation to unsubscribe from the stream', () => {
      expect(abortK8sPodLogsStreamMock).toHaveBeenCalledWith(
        {},
        {
          configuration,
          namespace: defaultProps.namespace,
          podName: defaultProps.podName,
          containerName: '',
        },
        expect.anything(),
        expect.anything(),
      );
    });
  });
});
