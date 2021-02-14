import { GlAlert, GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import CanaryUpdateModal from '~/environments/components/canary_update_modal.vue';
import updateCanaryIngress from '~/environments/graphql/mutations/update_canary_ingress.mutation.graphql';

describe('/environments/components/canary_update_modal.vue', () => {
  let wrapper;
  let modal;
  let mutate;

  const findAlert = () => wrapper.find(GlAlert);

  const createComponent = () => {
    mutate = jest.fn().mockResolvedValue();
    wrapper = mount(CanaryUpdateModal, {
      propsData: {
        environment: {
          name: 'staging',
          global_id: 'gid://environments/staging',
        },
        weight: 60,
        visible: true,
      },
      mocks: {
        $apollo: { mutate },
      },
    });
    modal = wrapper.find(GlModal);
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }

    wrapper = null;
  });

  beforeEach(() => {
    createComponent();
  });

  it('should bind the modal props', () => {
    expect(modal.props()).toMatchObject({
      modalId: 'confirm-canary-change',
      actionPrimary: {
        text: 'Change ratio',
        attributes: [{ variant: 'info' }],
      },
      actionCancel: { text: 'Cancel' },
    });
  });

  it('should display the new weights', () => {
    expect(modal.text()).toContain('Stable: 40');
    expect(modal.text()).toContain('Canary: 60');
  });

  it('should display the affected environment', () => {
    expect(modal.text()).toContain(
      'You are changing the ratio of the canary rollout for staging compared to the stable deployment to:',
    );
  });

  it('should update the weight on primary action', () => {
    modal.vm.$emit('primary');

    expect(mutate).toHaveBeenCalledWith({
      mutation: updateCanaryIngress,
      variables: {
        input: {
          id: 'gid://environments/staging',
          weight: 60,
        },
      },
    });
  });

  it('should do nothing on cancel', () => {
    modal.vm.$emit('secondary');
    expect(mutate).not.toHaveBeenCalled();
  });

  it('should not display an error if there was not one', async () => {
    mutate.mockResolvedValue({ data: { environmentsCanaryIngressUpdate: { errors: [] } } });
    modal.vm.$emit('primary');

    await wrapper.vm.$nextTick();

    expect(findAlert().exists()).toBe(false);
  });

  it('should display an error if there was one', async () => {
    mutate.mockResolvedValue({ data: { environmentsCanaryIngressUpdate: { errors: ['error'] } } });
    modal.vm.$emit('primary');

    await wrapper.vm.$nextTick();

    expect(findAlert().text()).toBe('error');
  });

  it('should display a generic error if there was a top-level one', async () => {
    mutate.mockRejectedValue();
    modal.vm.$emit('primary');

    await waitForPromises();
    await wrapper.vm.$nextTick();

    expect(findAlert().text()).toBe('Something went wrong. Please try again later');
  });

  it('hides teh alert on dismiss', async () => {
    mutate.mockResolvedValue({ data: { environmentsCanaryIngressUpdate: { errors: ['error'] } } });
    modal.vm.$emit('primary');

    await wrapper.vm.$nextTick();

    const alert = findAlert();
    alert.vm.$emit('dismiss');

    await wrapper.vm.$nextTick();

    expect(alert.exists()).toBe(false);
  });
});
