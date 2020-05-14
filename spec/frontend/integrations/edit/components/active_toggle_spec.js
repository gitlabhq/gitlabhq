import { mount } from '@vue/test-utils';
import ActiveToggle from '~/integrations/edit/components/active_toggle.vue';
import { GlToggle } from '@gitlab/ui';

const GL_TOGGLE_ACTIVE_CLASS = 'is-checked';

describe('ActiveToggle', () => {
  let wrapper;

  const defaultProps = {
    initialActivated: true,
  };

  const createComponent = props => {
    wrapper = mount(ActiveToggle, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findGlToggle = () => wrapper.find(GlToggle);
  const findButtonInToggle = () => findGlToggle().find('button');
  const findInputInToggle = () => findGlToggle().find('input');

  describe('template', () => {
    describe('initialActivated is false', () => {
      it('renders GlToggle as inactive', () => {
        createComponent({
          initialActivated: false,
        });

        expect(findGlToggle().exists()).toBe(true);
        expect(findButtonInToggle().classes()).not.toContain(GL_TOGGLE_ACTIVE_CLASS);
        expect(findInputInToggle().attributes('value')).toBe('false');
      });
    });

    describe('initialActivated is true', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders GlToggle as active', () => {
        expect(findGlToggle().exists()).toBe(true);
        expect(findButtonInToggle().classes()).toContain(GL_TOGGLE_ACTIVE_CLASS);
        expect(findInputInToggle().attributes('value')).toBe('true');
      });

      describe('on toggle click', () => {
        it('switches the form value', () => {
          findButtonInToggle().trigger('click');

          wrapper.vm.$nextTick(() => {
            expect(findButtonInToggle().classes()).not.toContain(GL_TOGGLE_ACTIVE_CLASS);
            expect(findInputInToggle().attributes('value')).toBe('false');
          });
        });
      });
    });
  });
});
