import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RunnerSummaryField from '~/ci/runner/components/cells/runner_summary_field.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('RunnerSummaryField', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const getTooltipValue = () => getBinding(wrapper.element, 'gl-tooltip').value;

  const createComponent = ({ props, ...options } = {}) => {
    wrapper = shallowMount(RunnerSummaryField, {
      propsData: {
        icon: '',
        tooltip: '',
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      ...options,
    });
  };

  it('shows content in slot', () => {
    createComponent({
      slots: { default: 'content' },
    });

    expect(wrapper.text()).toBe('content');
  });

  it('shows icon', () => {
    createComponent({ props: { icon: 'git' } });

    expect(findIcon().props('name')).toBe('git');
  });

  it('shows tooltip', () => {
    createComponent({ props: { tooltip: 'tooltip' } });

    expect(getTooltipValue()).toBe('tooltip');
  });
});
