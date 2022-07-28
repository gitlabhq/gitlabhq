import { shallowMount } from '@vue/test-utils';
import RunnerStatusStat from '~/runner/components/stat/runner_status_stat.vue';
import RunnerSingleStat from '~/runner/components/stat/runner_single_stat.vue';
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE, INSTANCE_TYPE } from '~/runner/constants';

describe('RunnerStatusStat', () => {
  let wrapper;

  const findRunnerSingleStat = () => wrapper.findComponent(RunnerSingleStat);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(RunnerStatusStat, {
      propsData: {
        scope: INSTANCE_TYPE,
        status: STATUS_ONLINE,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    status            | variant      | title                | metaText
    ${STATUS_ONLINE}  | ${'success'} | ${'Online runners'}  | ${'online'}
    ${STATUS_OFFLINE} | ${'muted'}   | ${'Offline runners'} | ${'offline'}
    ${STATUS_STALE}   | ${'warning'} | ${'Stale runners'}   | ${'stale'}
  `('Renders a stat for status "$status"', ({ status, variant, title, metaText }) => {
    beforeEach(() => {
      createComponent({ props: { status } });
    });

    it('Renders text', () => {
      expect(findRunnerSingleStat().attributes()).toMatchObject({
        variant,
        title,
        metatext: metaText,
      });
    });

    it('Passes filters', () => {
      expect(findRunnerSingleStat().props('variables')).toEqual({ status });
    });

    it('Does not skip query with no filters', () => {
      expect(findRunnerSingleStat().props('skip')).toEqual(false);
    });
  });

  it('Merges filters', () => {
    createComponent({ props: { status: STATUS_ONLINE, variables: { paused: true } } });

    expect(findRunnerSingleStat().props('variables')).toEqual({
      status: STATUS_ONLINE,
      paused: true,
    });
  });

  it('Skips query when other status is in the filters', () => {
    createComponent({ props: { status: STATUS_ONLINE, variables: { status: STATUS_OFFLINE } } });

    expect(findRunnerSingleStat().props('skip')).toEqual(true);
  });
});
