import BroadcastMessagesBase from '~/admin/broadcast_messages/components/base.vue';
import { generateMockMessages } from '../../../../../../spec/frontend/admin/broadcast_messages/mock_data';

export default {
  title: 'admin/broadcast_messages/base',
  component: BroadcastMessagesBase,
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { BroadcastMessagesBase },
  template: '<broadcast-messages-base v-bind="$props" />',
});

export const Default = Template.bind({});
Default.args = {
  page: 1,
  messagesCount: 5,
  messages: generateMockMessages(5),
};

export const Empty = Template.bind({});
Empty.args = {
  page: 1,
  messagesCount: 0,
  messages: [],
};
