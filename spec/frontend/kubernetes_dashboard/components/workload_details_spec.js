import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlTruncate } from '@gitlab/ui';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import WorkloadDetailsItem from '~/kubernetes_dashboard/components/workload_details_item.vue';
import { WORKLOAD_STATUS_BADGE_VARIANTS } from '~/kubernetes_dashboard/constants';
import PodLogsButton from '~/environments/environment_details/components/kubernetes/pod_logs_button.vue';
import { mockPodsTableItems } from '../graphql/mock_data';

let wrapper;

const defaultItem = mockPodsTableItems[2];

const createWrapper = (item = defaultItem) => {
  wrapper = shallowMount(WorkloadDetails, {
    propsData: {
      item,
    },
    stubs: { GlTruncate },
  });
};

const findAllWorkloadDetailsItems = () => wrapper.findAllComponents(WorkloadDetailsItem);
const findWorkloadDetailsItem = (at) => findAllWorkloadDetailsItems().at(at);
const findAllBadges = () => wrapper.findAllComponents(GlBadge);
const findBadge = (at) => findAllBadges().at(at);
const findAllPodLogsButtons = () => wrapper.findAllComponents(PodLogsButton);
const findPodLogsButton = (at) => findAllPodLogsButtons().at(at);

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
      createWrapper(mockPodsTableItems[0]);
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

    describe('when containers are provided', () => {
      const mockTableItemsWithContainers = {
        ...mockPodsTableItems[0],
        containers: [{ name: 'container-1' }, { name: 'container-2' }],
      };

      beforeEach(() => {
        createWrapper(mockTableItemsWithContainers);
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
  });
});
