import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import DropdownKeyboardNavigation from '~/vue_shared/components/dropdown_keyboard_navigation.vue';
import { UP_KEY_CODE, DOWN_KEY_CODE, TAB_KEY_CODE } from '~/lib/utils/keycodes';

const MOCK_INDEX = 0;
const MOCK_MAX = 10;
const MOCK_MIN = 0;
const MOCK_DEFAULT_INDEX = 0;

describe('DropdownKeyboardNavigation', () => {
  let wrapper;

  const defaultProps = {
    index: MOCK_INDEX,
    max: MOCK_MAX,
    min: MOCK_MIN,
    defaultIndex: MOCK_DEFAULT_INDEX,
  };

  const createComponent = (props) => {
    wrapper = shallowMount(DropdownKeyboardNavigation, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const helpers = {
    arrowDown: () => {
      document.dispatchEvent(new KeyboardEvent('keydown', { keyCode: DOWN_KEY_CODE }));
    },
    arrowUp: () => {
      document.dispatchEvent(new KeyboardEvent('keydown', { keyCode: UP_KEY_CODE }));
    },
    tab: () => {
      document.dispatchEvent(new KeyboardEvent('keydown', { keyCode: TAB_KEY_CODE }));
    },
  };

  describe('onInit', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should $emit @change with the default index', () => {
      expect(wrapper.emitted('change')[0]).toStrictEqual([MOCK_DEFAULT_INDEX]);
    });

    it('should $emit @change with the default index when max changes', async () => {
      wrapper.setProps({ max: 20 });
      await nextTick();
      // The first @change`call happens on created() so we test for the second [1]
      expect(wrapper.emitted('change')[1]).toStrictEqual([MOCK_DEFAULT_INDEX]);
    });
  });

  describe('keydown events', () => {
    beforeEach(() => {
      createComponent();
    });

    it('onKeydown-Tab $emits @tab event', () => {
      helpers.tab();

      expect(wrapper.emitted('tab')).toHaveLength(1);
    });
  });

  describe('increment', () => {
    describe('when max is 0', () => {
      beforeEach(() => {
        createComponent({ max: 0 });
      });

      it('does not $emit any @change events', () => {
        helpers.arrowDown();

        // The first @change`call happens on created() so we test that we only have 1 call
        expect(wrapper.emitted('change')).toHaveLength(1);
      });
    });

    describe.each`
      keyboardAction       | direction | index | max   | min
      ${helpers.arrowDown} | ${1}      | ${10} | ${10} | ${0}
      ${helpers.arrowUp}   | ${-1}     | ${0}  | ${10} | ${0}
    `('moving out of bounds', ({ keyboardAction, direction, index, max, min }) => {
      beforeEach(() => {
        createComponent({ index, max, min });
        keyboardAction();
      });

      it(`in ${direction} direction does not $emit any @change events`, () => {
        // The first @change`call happens on created() so we test that we only have 1 call
        expect(wrapper.emitted('change')).toHaveLength(1);
      });
    });

    describe.each`
      keyboardAction       | direction | index | max   | min
      ${helpers.arrowDown} | ${1}      | ${10} | ${10} | ${0}
      ${helpers.arrowUp}   | ${-1}     | ${0}  | ${10} | ${0}
    `(
      'moving out of bounds with cycle enabled',
      ({ keyboardAction, direction, index, max, min }) => {
        beforeEach(() => {
          createComponent({ index, max, min, enableCycle: true });
          keyboardAction();
        });

        it(`in ${direction} direction does $emit correct @change event`, () => {
          // The first @change`call happens on created() so we test that we only have 1 call
          expect(wrapper.emitted('change')[1]).toStrictEqual([direction === 1 ? min : max]);
        });
      },
    );

    describe.each`
      keyboardAction       | direction | index | max   | min
      ${helpers.arrowDown} | ${1}      | ${0}  | ${10} | ${0}
      ${helpers.arrowUp}   | ${-1}     | ${10} | ${10} | ${0}
    `('moving in bounds', ({ keyboardAction, direction, index, max, min }) => {
      beforeEach(() => {
        createComponent({ index, max, min });
        keyboardAction();
      });

      it(`in ${direction} direction $emits @change event with the correct index ${
        index + direction
      }`, () => {
        // The first @change`call happens on created() so we test for the second [1]
        expect(wrapper.emitted('change')[1]).toStrictEqual([index + direction]);
      });
    });
  });
});
