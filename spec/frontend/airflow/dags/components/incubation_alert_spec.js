import { mount } from '@vue/test-utils';
import { GlAlert, GlButton, GlLink } from '@gitlab/ui';
import IncubationAlert from '~/airflow/dags/components/incubation_alert.vue';

describe('IncubationAlert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const findButton = () => wrapper.findComponent(GlButton);

  const findHref = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = mount(IncubationAlert);
  });

  it('displays link to issue', () => {
    expect(findButton().attributes().href).toBe(
      'https://gitlab.com/gitlab-org/incubation-engineering/airflow/meta/-/issues/2',
    );
  });

  it('displays link to handbook', () => {
    expect(findHref().attributes().href).toBe(
      'https://about.gitlab.com/handbook/engineering/incubation/airflow/',
    );
  });

  it('is removed if dismissed', async () => {
    await wrapper.find('[aria-label="Dismiss"]').trigger('click');

    expect(findAlert().exists()).toBe(false);
  });
});
