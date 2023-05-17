import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import ParameterFormGroup from '~/feature_flags/components/strategies/parameter_form_group.vue';

describe('~/feature_flags/strategies/parameter_form_group.vue', () => {
  let wrapper;
  let formGroup;
  let slot;

  beforeEach(() => {
    wrapper = mount(ParameterFormGroup, {
      propsData: { inputId: 'test-id', label: 'test' },
      attrs: { description: 'test description' },
      scopedSlots: {
        default(props) {
          return this.$createElement(GlFormInput, {
            attrs: { id: props.inputId, 'data-testid': 'slot' },
          });
        },
      },
    });

    formGroup = wrapper.findComponent(GlFormGroup);
    slot = wrapper.find('[data-testid="slot"]');
  });

  it('should display the default slot', () => {
    expect(slot.exists()).toBe(true);
  });

  it('should bind the input id to the slot', () => {
    expect(slot.attributes('id')).toBe('test-id');
  });

  it('should bind the label-for to the input id', () => {
    expect(formGroup.find('[for="test-id"]').exists()).toBe(true);
  });

  it('should bind extra attributes to the form group', () => {
    expect(formGroup.attributes('description')).toBe('test description');
  });
});
