import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import actionBtn from '~/deploy_keys/components/action_btn.vue';
import eventHub from '~/deploy_keys/eventhub';

describe('Deploy keys action btn', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
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

  it('sends eventHub event with btn type', () => {
    jest.spyOn(eventHub, '$emit').mockImplementation(() => {});

    findButton().vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(eventHub.$emit).toHaveBeenCalledWith('enable.key', deployKey, expect.anything());
    });
  });

  it('shows loading spinner after click', () => {
    findButton().vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(findButton().props('loading')).toBe(true);
    });
  });
});
