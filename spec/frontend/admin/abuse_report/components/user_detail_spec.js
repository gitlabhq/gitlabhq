import { shallowMount } from '@vue/test-utils';
import UserDetail from '~/admin/abuse_report/components/user_detail.vue';

describe('UserDetail', () => {
  let wrapper;

  const label = 'user detail label';
  const value = 'user detail value';

  const createComponent = (props = {}, slots = {}) => {
    wrapper = shallowMount(UserDetail, {
      propsData: {
        label,
        value,
        ...props,
      },
      slots,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('UserDetail', () => {
    it('renders the label', () => {
      expect(wrapper.text()).toContain(label);
    });

    describe('rendering the value', () => {
      const slots = {
        default: ['slot provided user detail'],
      };

      describe('when `value` property and no default slot is provided', () => {
        it('renders the `value` as content', () => {
          expect(wrapper.text()).toContain(value);
        });
      });

      describe('when default slot and no `value` property is provided', () => {
        beforeEach(() => {
          createComponent({ label, value: null }, slots);
        });

        it('renders the content provided via the default slot', () => {
          expect(wrapper.text()).toContain(slots.default[0]);
        });
      });

      describe('when `value` property and default slot are both provided', () => {
        beforeEach(() => {
          createComponent({ label, value }, slots);
        });

        it('does not render `value` as content', () => {
          expect(wrapper.text()).not.toContain(value);
        });

        it('renders the content provided via the default slot', () => {
          expect(wrapper.text()).toContain(slots.default[0]);
        });
      });
    });
  });
});
