import { shallowMount } from '@vue/test-utils';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import WorkloadStats from '~/kubernetes_dashboard/components/workload_stats.vue';
import { mockPodStats } from '../graphql/mock_data';

let wrapper;

const createWrapper = () => {
  wrapper = shallowMount(WorkloadStats, {
    propsData: {
      stats: mockPodStats,
    },
  });
};

const findAllStats = () => wrapper.findAllComponents(GlSingleStat);
const findSingleStat = (at) => findAllStats().at(at);

describe('Workload stats component', () => {
  it('renders GlSingleStat component for each stat', () => {
    createWrapper();

    expect(findAllStats()).toHaveLength(4);
  });

  it.each`
    count | title          | index
    ${2}  | ${'Running'}   | ${0}
    ${1}  | ${'Pending'}   | ${1}
    ${1}  | ${'Succeeded'} | ${2}
    ${2}  | ${'Failed'}    | ${3}
  `(
    'renders stat with title "$title" and count "$count" at index $index',
    ({ count, title, index }) => {
      createWrapper();

      expect(findSingleStat(index).props()).toMatchObject({
        value: count,
        title,
      });
    },
  );
});
