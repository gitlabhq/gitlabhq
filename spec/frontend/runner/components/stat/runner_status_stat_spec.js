import { GlSingleStat } from '@gitlab/ui/dist/charts';
import { shallowMount, mount } from '@vue/test-utils';
import RunnerStatusStat from '~/runner/components/stat/runner_status_stat.vue';
import { STATUS_ONLINE, STATUS_OFFLINE, STATUS_STALE } from '~/runner/constants';

describe('RunnerStatusStat', () => {
  let wrapper;

  const findSingleStat = () => wrapper.findComponent(GlSingleStat);

  const createComponent = ({ props = {} } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(RunnerStatusStat, {
      propsData: {
        status: STATUS_ONLINE,
        value: 99,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    status            | variant      | title                | badge
    ${STATUS_ONLINE}  | ${'success'} | ${'Online runners'}  | ${'online'}
    ${STATUS_OFFLINE} | ${'muted'}   | ${'Offline runners'} | ${'offline'}
    ${STATUS_STALE}   | ${'warning'} | ${'Stale runners'}   | ${'stale'}
  `('Renders a stat for status "$status"', ({ status, variant, title, badge }) => {
    beforeEach(() => {
      createComponent({ props: { status } }, mount);
    });

    it('Renders text', () => {
      expect(wrapper.text()).toMatch(new RegExp(`${title} 99\\s+${badge}`));
    });

    it(`Uses variant ${variant}`, () => {
      expect(findSingleStat().props('variant')).toBe(variant);
    });
  });

  it('Formats stat number', () => {
    createComponent({ props: { value: 1000 } }, mount);

    expect(wrapper.text()).toMatch('Online runners 1,000');
  });

  it('Shows a null result', () => {
    createComponent({ props: { value: null } }, mount);

    expect(wrapper.text()).toMatch('Online runners -');
  });

  it('Shows an undefined result', () => {
    createComponent({ props: { value: undefined } }, mount);

    expect(wrapper.text()).toMatch('Online runners -');
  });

  it('Shows result for an unknown status', () => {
    createComponent({ props: { status: 'UNKNOWN' } }, mount);

    expect(wrapper.text()).toMatch('Runners 99');
  });
});
