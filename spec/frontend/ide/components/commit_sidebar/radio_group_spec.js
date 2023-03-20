import { GlFormRadioGroup } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import RadioGroup from '~/ide/components/commit_sidebar/radio_group.vue';
import { createStore } from '~/ide/stores';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

describe('IDE commit sidebar radio group', () => {
  let wrapper;
  let store;

  const createComponent = (config = {}) => {
    store = createStore();

    store.state.commit.commitAction = '2';
    store.state.commit.newBranchName = 'test-123';

    wrapper = mount(RadioGroup, {
      store,
      propsData: config.props,
      slots: config.slots,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe('without input', () => {
    const props = {
      value: '1',
      label: 'test',
      checked: true,
    };

    it('uses label if present', () => {
      createComponent({ props });

      expect(wrapper.text()).toContain('test');
    });

    it('uses slot if label is not present', () => {
      createComponent({ props: { value: '1', checked: true }, slots: { default: 'Testing slot' } });

      expect(wrapper.text()).toContain('Testing slot');
    });

    it('updates store when changing radio button', async () => {
      createComponent({ props });

      await wrapper.find('input').trigger('change');

      expect(store.state.commit.commitAction).toBe('1');
    });
  });

  describe('with input', () => {
    const props = {
      value: '2',
      label: 'test',
      checked: true,
      showInput: true,
    };

    it('renders input box when commitAction matches value', () => {
      createComponent({ props: { ...props, value: '2' } });

      expect(wrapper.find('.form-control').exists()).toBe(true);
    });

    it('hides input when commitAction doesnt match value', () => {
      createComponent({ props: { ...props, value: '1' } });

      expect(wrapper.find('.form-control').exists()).toBe(false);
    });

    it('updates branch name in store on input', async () => {
      createComponent({ props });

      await wrapper.find('.form-control').setValue('testing-123');

      expect(store.state.commit.newBranchName).toBe('testing-123');
    });

    it('renders newBranchName if present', () => {
      createComponent({ props });

      const input = wrapper.find('.form-control');

      expect(input.element.value).toBe('test-123');
    });
  });

  describe('tooltipTitle', () => {
    it('returns title when disabled', () => {
      createComponent({
        props: { value: '1', label: 'test', disabled: true, title: 'test title' },
      });

      const tooltip = getBinding(wrapper.findComponent(GlFormRadioGroup).element, 'gl-tooltip');
      expect(tooltip.value).toBe('test title');
    });

    it('returns blank when not disabled', () => {
      createComponent({
        props: { value: '1', label: 'test', title: 'test title' },
      });

      const tooltip = getBinding(wrapper.findComponent(GlFormRadioGroup).element, 'gl-tooltip');

      expect(tooltip.value).toBe('');
    });
  });
});
