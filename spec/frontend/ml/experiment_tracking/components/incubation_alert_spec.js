import { mount } from '@vue/test-utils';
import { GlAlert, GlButton } from '@gitlab/ui';
import IncubationAlert from '~/ml/experiment_tracking/components/incubation_alert.vue';

describe('IncubationAlert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = mount(IncubationAlert);
  });

  it('displays link to issue', () => {
    expect(findButton().attributes().href).toBe(
      'https://gitlab.com/gitlab-org/gitlab/-/issues/381660',
    );
  });

  it('is removed if dismissed', async () => {
    await wrapper.find('[aria-label="Dismiss"]').trigger('click');

    expect(findAlert().exists()).toBe(false);
  });
});
