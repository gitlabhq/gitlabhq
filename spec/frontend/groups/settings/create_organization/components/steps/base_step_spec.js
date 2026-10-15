import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import { Portal } from 'portal-vue';
import { stubComponent } from 'helpers/stub_component';
import BaseStep from '~/groups/settings/create_organization/components/steps/base_step.vue';
import { MODAL_FOOTER_PORTAL_NAME } from '~/groups/settings/create_organization/constants';

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
      stubs: {
        Portal: stubComponent(Portal, { props: ['to'] }),
      },
    });
  };

  const findIllustration = () => wrapper.find('img');
  const findPortal = () => wrapper.findComponent(Portal);
  const findPrevButton = () => findPortal().findAllComponents(GlButton).at(0);
  const findNextButton = () => findPortal().findAllComponents(GlButton).at(1);

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

  describe('footer buttons', () => {
    it('renders buttons in the modal footer portal', () => {
      createComponent();

      expect(findPortal().props('to')).toBe(MODAL_FOOTER_PORTAL_NAME);
    });

    describe('with default props', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders back text for prev button', () => {
        expect(findPrevButton().text()).toBe('Back');
      });

      it('renders continue text for next button', () => {
        expect(findNextButton().text()).toBe('Continue');
      });

      it('does not show next button as loading', () => {
        expect(findNextButton().props('loading')).toBe(false);
      });
    });

    describe('with custom props', () => {
      beforeEach(() => {
        createComponent({
          props: { prevButtonText: 'Cancel', nextButtonText: 'Confirm', nextButtonLoading: true },
        });
      });

      it('renders custom text for prev button', () => {
        expect(findPrevButton().text()).toBe('Cancel');
      });

      it('renders custom text for next button', () => {
        expect(findNextButton().text()).toBe('Confirm');
      });

      it('shows next button as loading', () => {
        expect(findNextButton().props('loading')).toBe(true);
      });
    });

    it('emits prev event when prev button is clicked', () => {
      createComponent();

      findPrevButton().vm.$emit('click');

      expect(wrapper.emitted('prev')).toEqual([[]]);
    });

    it('emits next event when next button is clicked', () => {
      createComponent();

      findNextButton().vm.$emit('click');

      expect(wrapper.emitted('next')).toEqual([[]]);
    });
  });
});
