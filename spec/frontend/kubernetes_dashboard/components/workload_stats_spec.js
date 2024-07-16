import { shallowMount } from '@vue/test-utils';
import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { nextTick } from 'vue';
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

  describe('selecting stat', () => {
    it('selects stat on click and adds appropriate CSS class', async () => {
      createWrapper();

      findSingleStat(0).vm.$emit('click');
      await nextTick();

      expect(findSingleStat(0).classes()).toContain('gl-shadow-inner-b-2-blue-500');
    });

    it('deselects stat with the second click', async () => {
      createWrapper();

      findSingleStat(1).vm.$emit('click');
      await nextTick();

      expect(findSingleStat(1).classes()).toContain('gl-shadow-inner-b-2-blue-500');

      findSingleStat(1).vm.$emit('click');
      await nextTick();

      expect(findSingleStat(1).classes()).not.toContain('gl-shadow-inner-b-2-blue-500');
    });

    it('emit a select event', async () => {
      createWrapper();

      findSingleStat(2).vm.$emit('click');
      await nextTick();

      expect(wrapper.emitted('select')).toEqual([[mockPodStats[2].title]]);
    });
  });
});
