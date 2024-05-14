import { GlCard, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import GlCardEmptyStateExperiment from '~/issues/list/components/gl_card_empty_state_experiment.vue';

describe('GlCardEmptyStateExperiment component', () => {
  let wrapper;

  const propsData = {
    icon: 'download',
  };

  const findGlCard = () => wrapper.findComponent(GlCard);
  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const findCardHeader = () => findGlCard().find('p');
  const findCardBody = () => findGlCard().find('.body-content');

  const mountComponent = () => {
    wrapper = shallowMount(GlCardEmptyStateExperiment, {
      propsData,
      slots: {
        header: 'Header content',
        body: '<div class="body-content">Body content</div>',
      },
    });
  };

  it('renders empty state experiment card', () => {
    mountComponent();

    expect(findGlCard().exists()).toBe(true);
    expect(findGlIcon().props('name')).toBe(propsData.icon);
    expect(findCardHeader().text()).toBe('Header content');
    expect(findCardBody().text()).toBe('Body content');
  });
});
