import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlTruncate } from '@gitlab/ui';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import WorkloadDetailsItem from '~/kubernetes_dashboard/components/workload_details_item.vue';
import { WORKLOAD_STATUS_BADGE_VARIANTS } from '~/kubernetes_dashboard/constants';
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
  });
});
