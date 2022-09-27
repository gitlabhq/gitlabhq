import { shallowMount } from '@vue/test-utils';
import BroadcastMessagesBase from '~/admin/broadcast_messages/components/base.vue';
import MessagesTable from '~/admin/broadcast_messages/components/messages_table.vue';
import { MOCK_MESSAGES } from '../mock_data';

describe('BroadcastMessagesBase', () => {
  let wrapper;

  const findTable = () => wrapper.findComponent(MessagesTable);

  function createComponent(props = {}) {
    wrapper = shallowMount(BroadcastMessagesBase, {
      propsData: {
        messages: MOCK_MESSAGES,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the table when there are existing messages', () => {
    createComponent();

    expect(findTable().exists()).toBe(true);
  });

  it('does not render the table when there are no existing messages', () => {
    createComponent({ messages: [] });

    expect(findTable().exists()).toBe(false);
  });
});
