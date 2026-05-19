import { shallowMount } from '@vue/test-utils';
import BaseStep from '~/organizations/index/components/reconciliation/steps/base_step.vue';

describe('ReconciliationBaseStep', () => {
  let wrapper;

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMount(BaseStep, {
      propsData: {
        ...props,
      },
      slots: {
        default: '<p>Slot content</p>',
        ...slots,
      },
    });
  };

  const findIllustration = () => wrapper.find('img');

  it('renders default slot content', () => {
    createComponent();

    expect(wrapper.text()).toContain('Slot content');
  });

  it('renders description slot content', () => {
    createComponent({ slots: { description: '<p>Description content</p>' } });

    expect(wrapper.text()).toContain('Description content');
  });

  it('renders illustration when provided', () => {
    createComponent({ props: { illustration: '/path/to/illustration.svg' } });

    expect(findIllustration().element.src).toBe('/path/to/illustration.svg');
  });

  it('does not render illustration when not provided', () => {
    createComponent();

    expect(findIllustration().exists()).toBe(false);
  });

  it('renders title when provided', () => {
    createComponent({ props: { title: 'Step title' } });

    expect(wrapper.find('h2').text()).toBe('Step title');
  });

  it('does not render title when not provided', () => {
    createComponent();

    expect(wrapper.find('h2').exists()).toBe(false);
  });
});
