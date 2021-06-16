import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RunnerTypeCell from '~/runner/components/cells/runner_type_cell.vue';
import { INSTANCE_TYPE } from '~/runner/constants';

describe('RunnerTypeCell', () => {
  let wrapper;

  const findBadges = () => wrapper.findAllComponents(GlBadge);

  const createComponent = ({ runner = {} } = {}) => {
    wrapper = mount(RunnerTypeCell, {
      propsData: {
        runner: {
          runnerType: INSTANCE_TYPE,
          active: true,
          locked: false,
          ...runner,
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays the runner type', () => {
    createComponent();

    expect(findBadges()).toHaveLength(1);
    expect(findBadges().at(0).text()).toBe('shared');
  });

  it('Displays locked and paused states', () => {
    createComponent({
      runner: {
        active: false,
        locked: true,
      },
    });

    expect(findBadges()).toHaveLength(3);
    expect(findBadges().at(0).text()).toBe('shared');
    expect(findBadges().at(1).text()).toBe('locked');
    expect(findBadges().at(2).text()).toBe('paused');
  });
});
