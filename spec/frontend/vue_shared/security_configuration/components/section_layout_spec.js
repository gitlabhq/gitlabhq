import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import SectionLoader from '~/vue_shared/security_configuration/components/section_loader.vue';

describe('Section Layout component', () => {
  let wrapper;

  const createComponent = (
    propsData,
    scopedSlots = {
      description: '<span>foo</span>',
      features: '<span>bar</span>',
    },
  ) => {
    wrapper = extendedWrapper(
      mount(SectionLayout, {
        propsData,
        scopedSlots,
      }),
    );
  };

  const findHeading = () => wrapper.find('h2');
  const findLoader = () => wrapper.findComponent(SectionLoader);

  describe('basic structure', () => {
    beforeEach(() => {
      createComponent({ heading: 'testheading' });
    });

    const slots = {
      description: 'foo',
      features: 'bar',
    };

    it('should render heading when passed in as props', () => {
      expect(findHeading().exists()).toBe(true);
      expect(findHeading().text()).toBe('testheading');
    });

    it('should render slot content when no heading prop is passed', () => {
      createComponent({}, { heading: '<span>custom heading</span>' });

      expect(findHeading().exists()).toBe(false);
      expect(wrapper.text()).toBe('custom heading');
    });

    Object.keys(slots).forEach((slot) => {
      it('renders the slots', () => {
        const slotContent = slots[slot];
        createComponent({ heading: '' });
        expect(wrapper.text()).toContain(slotContent);
      });
    });
  });

  describe('loading state', () => {
    it('should show loaders when loading', () => {
      createComponent({ heading: 'testheading', isLoading: true });
      expect(findLoader().exists()).toBe(true);
    });
  });
});
