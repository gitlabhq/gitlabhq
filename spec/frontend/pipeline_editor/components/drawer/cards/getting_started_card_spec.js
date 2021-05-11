import { shallowMount } from '@vue/test-utils';
import GettingStartedCard from '~/pipeline_editor/components/drawer/cards/getting_started_card.vue';

describe('Getting started card', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GettingStartedCard);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the title', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.title);
  });

  it('renders the content', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.firstParagraph);
  });
});
