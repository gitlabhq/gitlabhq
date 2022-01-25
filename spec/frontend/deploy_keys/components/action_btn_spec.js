import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import data from 'test_fixtures/deploy_keys/keys.json';
import actionBtn from '~/deploy_keys/components/action_btn.vue';
import eventHub from '~/deploy_keys/eventhub';

describe('Deploy keys action btn', () => {
  const deployKey = data.enabled_keys[0];
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = shallowMount(actionBtn, {
      propsData: {
        deployKey,
        type: 'enable',
        category: 'primary',
        variant: 'confirm',
        icon: 'edit',
      },
      slots: {
        default: 'Enable',
      },
    });
  });

  it('renders the default slot', () => {
    expect(wrapper.text()).toBe('Enable');
  });

  it('passes the button props on', () => {
    expect(findButton().props()).toMatchObject({
      category: 'primary',
      variant: 'confirm',
      icon: 'edit',
    });
  });

  it('sends eventHub event with btn type', async () => {
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    findButton().vm.$emit('click');

    await nextTick();
    expect(eventHub.$emit).toHaveBeenCalledWith('enable.key', deployKey, expect.anything());
  });

  it('shows loading spinner after click', async () => {
    findButton().vm.$emit('click');

    await nextTick();
    expect(findButton().props('loading')).toBe(true);
  });
});
