import { shallowMount } from '@vue/test-utils';
import MessagesTableRow from '~/admin/broadcast_messages/components/messages_table_row.vue';
import { MOCK_MESSAGE } from '../mock_data';

describe('MessagesTableRow', () => {
  let wrapper;

  function createComponent(props = {}) {
    wrapper = shallowMount(MessagesTableRow, {
      propsData: {
        message: MOCK_MESSAGE,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the message ID', () => {
    createComponent();

    expect(wrapper.text()).toBe(`${MOCK_MESSAGE.id}`);
  });
});
