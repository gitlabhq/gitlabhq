import { GlBadge } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RunnerTypeHelp from '~/runner/components/runner_type_help.vue';

describe('RunnerTypeHelp', () => {
  let wrapper;

  const findBadges = () => wrapper.findAllComponents(GlBadge);

  const createComponent = () => {
    wrapper = mount(RunnerTypeHelp);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('Displays each of the runner types', () => {
    expect(findBadges().at(0).text()).toBe('shared');
    expect(findBadges().at(1).text()).toBe('group');
    expect(findBadges().at(2).text()).toBe('specific');
  });

  it('Displays runner states', () => {
    expect(findBadges().at(3).text()).toBe('locked');
    expect(findBadges().at(4).text()).toBe('paused');
  });
});
