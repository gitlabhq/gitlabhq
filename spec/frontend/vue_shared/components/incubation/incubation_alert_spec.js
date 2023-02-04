import { mount } from '@vue/test-utils';
import { GlAlert, GlButton } from '@gitlab/ui';
import IncubationAlert from '~/vue_shared/components/incubation/incubation_alert.vue';

describe('IncubationAlert', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const findButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = mount(IncubationAlert, {
      propsData: {
        featureName: 'some feature',
        linkToFeedbackIssue: 'some_link',
      },
    });
  });

  it('displays the feature name in the title', () => {
    expect(wrapper.html()).toContain('some feature is in incubating phase');
  });

  it('displays link to issue', () => {
    expect(findButton().attributes().href).toBe('some_link');
  });

  it('is removed if dismissed', async () => {
    await wrapper.find('[aria-label="Dismiss"]').trigger('click');

    expect(findAlert().exists()).toBe(false);
  });
});
