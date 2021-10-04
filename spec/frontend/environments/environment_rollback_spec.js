import { GlDropdownItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RollbackComponent from '~/environments/components/environment_rollback.vue';
import eventHub from '~/environments/event_hub';

describe('Rollback Component', () => {
  const retryUrl = 'https://gitlab.com/retry';

  it('Should render Re-deploy label when isLastDeployment is true', () => {
    const wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        isLastDeployment: true,
        environment: {},
      },
    });

    expect(wrapper.text()).toBe('Re-deploy to environment');
  });

  it('Should render Rollback label when isLastDeployment is false', () => {
    const wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        isLastDeployment: false,
        environment: {},
      },
    });

    expect(wrapper.text()).toBe('Rollback environment');
  });

  it('should emit a "rollback" event on button click', () => {
    const eventHubSpy = jest.spyOn(eventHub, '$emit');
    const wrapper = shallowMount(RollbackComponent, {
      propsData: {
        retryUrl,
        environment: {
          name: 'test',
        },
      },
    });
    const button = wrapper.find(GlDropdownItem);

    button.vm.$emit('click');

    expect(eventHubSpy).toHaveBeenCalledWith('requestRollbackEnvironment', {
      retryUrl,
      isLastDeployment: true,
      name: 'test',
    });
  });
});
