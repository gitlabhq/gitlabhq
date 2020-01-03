import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import eventHub from '~/environments/event_hub';
import PinComponent from '~/environments/components/environment_pin.vue';

describe('Pin Component', () => {
  let wrapper;

  const factory = (options = {}) => {
    // This destroys any wrappers created before a nested call to factory reassigns it
    if (wrapper && wrapper.destroy) {
      wrapper.destroy();
    }
    wrapper = shallowMount(PinComponent, {
      ...options,
    });
  };

  const autoStopUrl = '/root/auto-stop-env-test/-/environments/38/cancel_auto_stop';

  beforeEach(() => {
    factory({
      propsData: {
        autoStopUrl,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render the component with thumbtack icon', () => {
    expect(wrapper.find(Icon).props('name')).toBe('thumbtack');
  });

  it('should emit onPinClick when clicked', () => {
    const eventHubSpy = jest.spyOn(eventHub, '$emit');
    const button = wrapper.find(GlButton);

    button.vm.$emit('click');

    expect(eventHubSpy).toHaveBeenCalledWith('cancelAutoStop', autoStopUrl);
  });
});
