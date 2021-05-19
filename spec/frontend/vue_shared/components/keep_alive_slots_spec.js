import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import KeepAliveSlots from '~/vue_shared/components/keep_alive_slots.vue';

const SLOT_1 = {
  slotKey: 'slot-1',
  title: 'Hello 1',
};
const SLOT_2 = {
  slotKey: 'slot-2',
  title: 'Hello 2',
};

describe('~/vue_shared/components/keep_alive_slots.vue', () => {
  let wrapper;

  const createSlotContent = ({ slotKey, title }) => `
    <div data-testid="slot-child" data-slot-id="${slotKey}">
      <h1>${title}</h1>
      <input type="text" />
    </div>
  `;
  const createComponent = (props = {}) => {
    wrapper = mountExtended(KeepAliveSlots, {
      propsData: props,
      slots: {
        [SLOT_1.slotKey]: createSlotContent(SLOT_1),
        [SLOT_2.slotKey]: createSlotContent(SLOT_2),
      },
    });
  };

  const findRenderedSlots = () =>
    wrapper.findAllByTestId('slot-child').wrappers.map((x) => ({
      title: x.find('h1').text(),
      inputValue: x.find('input').element.value,
      isVisible: x.isVisible(),
    }));

  afterEach(() => {
    wrapper.destroy();
  });

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('doesnt show anything', () => {
      expect(findRenderedSlots()).toEqual([]);
    });

    describe('when slotKey is changed', () => {
      beforeEach(async () => {
        wrapper.setProps({ slotKey: SLOT_1.slotKey });
        await nextTick();
      });

      it('shows slot', () => {
        expect(findRenderedSlots()).toEqual([
          {
            title: SLOT_1.title,
            isVisible: true,
            inputValue: '',
          },
        ]);
      });

      it('hides everything when slotKey cannot be found', async () => {
        wrapper.setProps({ slotKey: '' });
        await nextTick();

        expect(findRenderedSlots()).toEqual([
          {
            title: SLOT_1.title,
            isVisible: false,
            inputValue: '',
          },
        ]);
      });

      describe('when user intreracts then slotKey changes again', () => {
        beforeEach(async () => {
          wrapper.find('input').setValue('TEST');
          wrapper.setProps({ slotKey: SLOT_2.slotKey });
          await nextTick();
        });

        it('keeps first slot alive but hidden', () => {
          expect(findRenderedSlots()).toEqual([
            {
              title: SLOT_1.title,
              isVisible: false,
              inputValue: 'TEST',
            },
            {
              title: SLOT_2.title,
              isVisible: true,
              inputValue: '',
            },
          ]);
        });
      });
    });
  });

  describe('initialized with slotKey', () => {
    beforeEach(() => {
      createComponent({ slotKey: SLOT_2.slotKey });
    });

    it('shows slot', () => {
      expect(findRenderedSlots()).toEqual([
        {
          title: SLOT_2.title,
          isVisible: true,
          inputValue: '',
        },
      ]);
    });
  });
});
