import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlTruncate, GlButton, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import WorkloadDetailsItem from '~/kubernetes_dashboard/components/workload_details_item.vue';
import { WORKLOAD_STATUS_BADGE_VARIANTS } from '~/kubernetes_dashboard/constants';
import PodLogsButton from '~/environments/environment_details/components/kubernetes/pod_logs_button.vue';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import K8sEventItem from '~/kubernetes_dashboard/components/k8s_event_item.vue';
import { mockPodsTableItems, k8sEventsMock } from '../graphql/mock_data';

Vue.use(VueApollo);

let wrapper;
let getK8sEventsQuery;

const defaultItem = mockPodsTableItems[2];
const configuration = {
  basePath: 'kas/tunnel/url',
  baseOptions: {
    headers: { 'GitLab-Agent-Id': '1' },
  },
};

const createWrapper = ({ item = defaultItem, selectedSection = '' } = {}) => {
  wrapper = shallowMount(WorkloadDetails, {
    propsData: {
      item,
      selectedSection,
    },
    stubs: { GlTruncate },
  });
};

const createApolloProvider = () => {
  const mockResolvers = {
    Query: {
      k8sEvents: getK8sEventsQuery,
    },
  };

  return createMockApollo([], mockResolvers);
};

const createWrapperWithApollo = () => {
  wrapper = shallowMount(WorkloadDetails, {
    propsData: {
      item: defaultItem,
      configuration,
    },
    apolloProvider: createApolloProvider(),
  });
};

const findAllWorkloadDetailsItems = () => wrapper.findAllComponents(WorkloadDetailsItem);
const findWorkloadDetailsItem = (at) => findAllWorkloadDetailsItems().at(at);
const findAllBadges = () => wrapper.findAllComponents(GlBadge);
const findBadge = (at) => findAllBadges().at(at);
const findAllPodLogsButtons = () => wrapper.findAllComponents(PodLogsButton);
const findPodLogsButton = (at) => findAllPodLogsButtons().at(at);
const findAllButtons = () => wrapper.findAllComponents(GlButton);
const findButton = (at) => findAllButtons().at(at);
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findAlert = () => wrapper.findComponent(GlAlert);
const findAllK8sEventItems = () => wrapper.findAllComponents(K8sEventItem);
const findK8sEventItem = (at) => findAllK8sEventItems().at(at);

describe('Workload details component', () => {
  describe('when minimal fields are provided', () => {
    beforeEach(() => {
      createWrapper();
    });

    it.each`
      label            | data                                 | collapsible | index
      ${'Name'}        | ${defaultItem.name}                  | ${false}    | ${0}
      ${'Kind'}        | ${defaultItem.kind}                  | ${false}    | ${1}
      ${'Labels'}      | ${'key=value'}                       | ${false}    | ${2}
      ${'Status'}      | ${defaultItem.status}                | ${false}    | ${3}
      ${'Annotations'} | ${'annotation: text\nanother: text'} | ${true}     | ${4}
    `('renders a list item for $label', ({ label, data, collapsible, index }) => {
      expect(findWorkloadDetailsItem(index).props('label')).toBe(label);
      expect(findWorkloadDetailsItem(index).text()).toMatchInterpolatedText(data);
      expect(findWorkloadDetailsItem(index).props('collapsible')).toBe(collapsible);
    });

    it('renders a badge for each of the labels', () => {
      const label = 'key=value';
      expect(findAllBadges()).toHaveLength(2);
      expect(findBadge(0).text()).toBe(label);
    });

    it('renders a badge for the status value', () => {
      const { status } = defaultItem;
      expect(findBadge(1).text()).toBe(status);
      expect(findBadge(1).props('variant')).toBe(WORKLOAD_STATUS_BADGE_VARIANTS[status]);
    });
  });

  describe('when additional fields are provided', () => {
    beforeEach(() => {
      createWrapper({ item: mockPodsTableItems[0] });
    });

    it.each`
      label            | yaml                                                         | index
      ${'Status'}      | ${'phase: Running\nready: true\nrestartCount: 4'}            | ${3}
      ${'Annotations'} | ${'annotation: text\nanother: text'}                         | ${4}
      ${'Spec'}        | ${'restartPolicy: Never\nterminationGracePeriodSeconds: 30'} | ${5}
    `('renders a collapsible list item for $label with the yaml code', ({ label, yaml, index }) => {
      expect(findWorkloadDetailsItem(index).props('label')).toBe(label);
      expect(findWorkloadDetailsItem(index).text()).toBe(yaml);
      expect(findWorkloadDetailsItem(index).props('collapsible')).toBe(true);
    });

    describe('when actions are provided', () => {
      const actions = [
        {
          name: 'delete-pod',
          text: 'Delete pod',
          icon: 'remove',
          variant: 'danger',
        },
      ];
      const mockTableItemsWithActions = {
        ...mockPodsTableItems[0],
        actions,
      };

      beforeEach(() => {
        createWrapper({ item: mockTableItemsWithActions });
      });

      it('renders a non-collapsible list item for containers', () => {
        expect(findWorkloadDetailsItem(1).props('label')).toBe('Actions');
        expect(findWorkloadDetailsItem(1).props('collapsible')).toBe(false);
      });

      it('renders a button for each action', () => {
        expect(findAllButtons()).toHaveLength(1);
      });

      it.each(actions)('renders a button with the correct props', (action) => {
        const currentIndex = actions.indexOf(action);

        expect(findButton(currentIndex).props()).toMatchObject({
          variant: action.variant,
          icon: action.icon,
        });

        expect(findButton(currentIndex).attributes()).toMatchObject({
          title: action.text,
          'aria-label': action.text,
        });
      });
    });

    describe('when containers are provided', () => {
      const mockTableItemsWithContainers = {
        ...mockPodsTableItems[0],
        containers: [{ name: 'container-1' }, { name: 'container-2' }],
      };

      beforeEach(() => {
        createWrapper({ item: mockTableItemsWithContainers });
      });

      it('renders a non-collapsible list item for containers', () => {
        expect(findWorkloadDetailsItem(6).props('label')).toBe('Containers');
        expect(findWorkloadDetailsItem(6).text()).toContain('container-1');
        expect(findWorkloadDetailsItem(6).text()).toContain('container-2');
        expect(findWorkloadDetailsItem(6).props('collapsible')).toBe(false);
      });

      it('renders a pod-logs-button for each container', () => {
        expect(findAllPodLogsButtons()).toHaveLength(2);
      });

      it.each`
        containerName    | container                  | index
        ${'container-1'} | ${{ name: 'container-1' }} | ${0}
        ${'container-2'} | ${{ name: 'container-2' }} | ${1}
      `(
        'renders a pod-logs-button with correct props for $containerName',
        ({ container, index }) => {
          const pod = mockTableItemsWithContainers;

          expect(findPodLogsButton(index).props()).toEqual({
            podName: pod.name,
            namespace: pod.namespace,
            containers: [container],
          });
        },
      );
    });

    describe('when selectedSection is `status`', () => {
      beforeEach(() => {
        createWrapper({ item: mockPodsTableItems[0], selectedSection: 'status' });
      });

      it.each`
        index | isExpanded | description
        ${0}  | ${false}   | ${'name item'}
        ${1}  | ${false}   | ${'kind item'}
        ${2}  | ${false}   | ${'labels item'}
        ${3}  | ${true}    | ${'status item'}
        ${4}  | ${false}   | ${'annotations item'}
      `(
        'provides isExpanded=$isExpanded to $description at index $index',
        ({ index, isExpanded }) => {
          expect(findWorkloadDetailsItem(index).props('isExpanded')).toBe(isExpanded);
        },
      );
    });

    describe('k8s events', () => {
      describe('default', () => {
        beforeEach(() => {
          getK8sEventsQuery = jest.fn().mockResolvedValue([]);
          createWrapperWithApollo();
        });
        it('renders a collapsible list item for events', () => {
          expect(findWorkloadDetailsItem(6).props('label')).toBe('Events');
        });

        it('requests k8s events for the current item', async () => {
          getK8sEventsQuery = jest.fn().mockResolvedValue([]);
          createWrapperWithApollo();
          await nextTick();

          expect(getK8sEventsQuery).toHaveBeenCalledWith(
            {},
            expect.objectContaining({
              configuration,
              namespace: defaultItem.namespace,
              involvedObjectName: defaultItem.name,
            }),
            expect.any(Object),
            expect.any(Object),
          );
        });

        it('renders loading icon while loading events', async () => {
          getK8sEventsQuery = jest.fn().mockResolvedValue([]);
          createWrapperWithApollo();
          await nextTick();

          expect(findLoadingIcon().exists()).toBe(true);
          await waitForPromises();

          expect(findLoadingIcon().exists()).toBe(false);
        });

        it('shows empty state message when no events are found', async () => {
          getK8sEventsQuery = jest.fn().mockResolvedValue([]);
          createWrapperWithApollo();
          await waitForPromises();

          expect(findWorkloadDetailsItem(6).text()).toBe('No events available');
        });
      });

      it('renders error alert when the request errored', async () => {
        const error = new Error('Error from the cluster_client API');
        getK8sEventsQuery = jest.fn().mockRejectedValue(error);
        createWrapperWithApollo();
        await waitForPromises();

        expect(findAlert().text()).toBe(error.message);
      });

      it("renders a list of k8s-event-item's for each event", async () => {
        getK8sEventsQuery = jest.fn().mockResolvedValue(k8sEventsMock);
        createWrapperWithApollo();
        await waitForPromises();

        expect(findAllK8sEventItems()).toHaveLength(k8sEventsMock.length);
      });

      it.each`
        lastTimestamp             | eventTime                 | timestamp
        ${'2023-05-01T12:00:00Z'} | ${''}                     | ${'2023-05-01T12:00:00Z'}
        ${''}                     | ${'2023-07-02T12:00:00Z'} | ${'2023-07-02T12:00:00Z'}
        ${'2023-05-01T12:00:00Z'} | ${'2023-07-02T12:00:00Z'} | ${'2023-05-01T12:00:00Z'}
        ${''}                     | ${''}                     | ${''}
      `(
        'renders timestamp as "$timestamp" when lastTimestamp is "$lastTimestamp" and eventTime is "$eventTime"',
        async ({ lastTimestamp, eventTime, timestamp }) => {
          const eventMock = {
            ...k8sEventsMock[0],
            lastTimestamp,
            eventTime,
          };

          getK8sEventsQuery = jest.fn().mockResolvedValue([eventMock]);
          createWrapperWithApollo();
          await waitForPromises();

          expect(findK8sEventItem(0).props('event').timestamp).toBe(timestamp);
        },
      );
    });
  });
});
