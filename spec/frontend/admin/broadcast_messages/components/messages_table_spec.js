import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import MessagesTable from '~/admin/broadcast_messages/components/messages_table.vue';
import { MOCK_MESSAGES } from '../mock_data';

describe('MessagesTable', () => {
  let wrapper;

  const findRows = () => wrapper.findAll('[data-testid="message-row"]');
  const findTargetRoles = () => wrapper.find('[data-testid="target-roles-th"]');
  const findDeleteButton = (id) => wrapper.find(`[data-testid="delete-message-${id}"]`);
  const findModal = () => wrapper.findComponent(GlModal);

  function createComponent(props = {}) {
    wrapper = mount(MessagesTable, {
      propsData: {
        messages: MOCK_MESSAGES,
        ...props,
      },
    });
  }

  it('renders a table row for each message', () => {
    createComponent();

    expect(findRows()).toHaveLength(MOCK_MESSAGES.length);
  });

  it('renders the "Target Roles" column', () => {
    createComponent();

    expect(findTargetRoles().exists()).toBe(true);
  });

  it('emits a delete-message event when a delete button is clicked', () => {
    const { id } = MOCK_MESSAGES[0];
    createComponent();
    findDeleteButton(id).element.click();
    findModal().vm.$emit('primary');

    expect(wrapper.emitted('delete-message')).toHaveLength(1);
    expect(wrapper.emitted('delete-message')[0]).toEqual([id]);
  });
});
