import { shallowMount } from '@vue/test-utils';
import MessagesTable from '~/admin/broadcast_messages/components/messages_table.vue';
import MessagesTableRow from '~/admin/broadcast_messages/components/messages_table_row.vue';
import { MOCK_MESSAGES } from '../mock_data';

describe('MessagesTable', () => {
  let wrapper;

  const findRows = () => wrapper.findAllComponents(MessagesTableRow);

  function createComponent(props = {}) {
    wrapper = shallowMount(MessagesTable, {
      propsData: {
        messages: MOCK_MESSAGES,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a table row for each message', () => {
    createComponent();

    expect(findRows()).toHaveLength(MOCK_MESSAGES.length);
  });
});
