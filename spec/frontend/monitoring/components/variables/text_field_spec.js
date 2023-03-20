import { GlFormInput } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import TextField from '~/monitoring/components/variables/text_field.vue';

describe('Text variable component', () => {
  let wrapper;
  const propsData = {
    name: 'pod',
    label: 'Select pod',
    value: 'test-pod',
  };
  const createShallowWrapper = () => {
    wrapper = shallowMount(TextField, {
      propsData,
    });
  };

  const findInput = () => wrapper.findComponent(GlFormInput);

  it('renders a text input when all props are passed', () => {
    createShallowWrapper();

    expect(findInput().exists()).toBe(true);
  });

  it('always has a default value', async () => {
    createShallowWrapper();

    await nextTick();
    expect(findInput().attributes('value')).toBe(propsData.value);
  });

  it('triggers keyup enter', async () => {
    createShallowWrapper();

    findInput().element.value = 'prod-pod';
    findInput().trigger('input');
    findInput().trigger('keyup.enter');

    await nextTick();
    expect(wrapper.emitted('input')).toEqual([['prod-pod']]);
  });

  it('triggers blur enter', async () => {
    createShallowWrapper();

    findInput().element.value = 'canary-pod';
    findInput().trigger('input');
    findInput().trigger('blur');

    await nextTick();
    expect(wrapper.emitted('input')).toEqual([['canary-pod']]);
  });
});
