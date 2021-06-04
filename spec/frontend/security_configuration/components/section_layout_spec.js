import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import SectionLayout from '~/security_configuration/components/section_layout.vue';

describe('Section Layout component', () => {
  let wrapper;

  const createComponent = (propsData) => {
    wrapper = extendedWrapper(
      mount(SectionLayout, {
        propsData,
        scopedSlots: {
          description: '<span>foo</span>',
          features: '<span>bar</span>',
        },
      }),
    );
  };

  const findHeading = () => wrapper.find('h2');

  afterEach(() => {
    wrapper.destroy();
  });

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

    Object.keys(slots).forEach((slot) => {
      it('renders the slots', () => {
        const slotContent = slots[slot];
        createComponent({ heading: '' });
        expect(wrapper.text()).toContain(slotContent);
      });
    });
  });
});
