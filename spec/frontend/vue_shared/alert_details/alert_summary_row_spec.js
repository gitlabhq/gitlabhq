import { shallowMount } from '@vue/test-utils';
import AlertSummaryRow from '~/vue_shared/alert_details/components/alert_summary_row.vue';

const label = 'a label';
const value = 'a value';

describe('AlertSummaryRow', () => {
  let wrapper;

  function mountComponent({ mountMethod = shallowMount, props, defaultSlot } = {}) {
    wrapper = mountMethod(AlertSummaryRow, {
      propsData: props,
      scopedSlots: {
        default: defaultSlot,
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('Alert Summary Row', () => {
    beforeEach(() => {
      mountComponent({
        props: {
          label,
        },
        defaultSlot: `<span class="value">${value}</span>`,
      });
    });

    it('should display a label and a value', () => {
      expect(wrapper.text()).toBe(`${label} ${value}`);
    });
  });
});
