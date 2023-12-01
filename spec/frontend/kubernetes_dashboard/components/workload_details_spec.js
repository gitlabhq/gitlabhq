import { shallowMount } from '@vue/test-utils';
import { GlBadge, GlTruncate } from '@gitlab/ui';
import WorkloadDetails from '~/kubernetes_dashboard/components/workload_details.vue';
import WorkloadDetailsItem from '~/kubernetes_dashboard/components/workload_details_item.vue';
import { WORKLOAD_STATUS_BADGE_VARIANTS } from '~/kubernetes_dashboard/constants';
import { mockPodsTableItems } from '../graphql/mock_data';

let wrapper;

const defaultItem = mockPodsTableItems[0];

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
  beforeEach(() => {
    createWrapper();
  });

  it.each`
    label            | data                                | index
    ${'Name'}        | ${defaultItem.name}                 | ${0}
    ${'Kind'}        | ${defaultItem.kind}                 | ${1}
    ${'Labels'}      | ${'key=value'}                      | ${2}
    ${'Status'}      | ${defaultItem.status}               | ${3}
    ${'Annotations'} | ${'annotation: text another: text'} | ${4}
  `('renders a list item for each not empty value', ({ label, data, index }) => {
    expect(findWorkloadDetailsItem(index).props('label')).toBe(label);
    expect(findWorkloadDetailsItem(index).text()).toMatchInterpolatedText(data);
  });

  it('renders a badge for each of the labels', () => {
    const label = 'key=value';
    expect(findBadge(0).text()).toBe(label);
  });

  it('renders a badge for the status value', () => {
    const { status } = defaultItem;
    expect(findBadge(1).text()).toBe(status);
    expect(findBadge(1).props('variant')).toBe(WORKLOAD_STATUS_BADGE_VARIANTS[status]);
  });
});
