import { shallowMount } from '@vue/test-utils';
import { GlPagination } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import BroadcastMessagesBase from '~/admin/broadcast_messages/components/base.vue';
import MessagesTable from '~/admin/broadcast_messages/components/messages_table.vue';
import { generateMockMessages, MOCK_MESSAGES } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('BroadcastMessagesBase', () => {
  let wrapper;
  let axiosMock;

  useMockLocationHelper();

  const findTable = () => wrapper.findComponent(MessagesTable);
  const findPagination = () => wrapper.findComponent(GlPagination);

  function createComponent(props = {}) {
    wrapper = shallowMount(BroadcastMessagesBase, {
      propsData: {
        page: 1,
        messagesCount: MOCK_MESSAGES.length,
        messages: MOCK_MESSAGES,
        ...props,
      },
      stubs: {
        CrudComponent,
      },
    });
  }

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('renders the table and pagination when there are existing messages', () => {
    createComponent();

    expect(findTable().exists()).toBe(true);
    expect(findPagination().exists()).toBe(true);
  });

  it('does not render the table when there are no visible messages', () => {
    createComponent({ messages: [] });

    expect(findTable().exists()).toBe(false);
    expect(findPagination().exists()).toBe(true);
  });

  it('does not remove a deleted message if it was not in visibleMessages', async () => {
    createComponent();

    findTable().vm.$emit('delete-message', -1);
    await waitForPromises();

    expect(axiosMock.history.delete).toHaveLength(0);
    expect(findTable().props('messages')).toHaveLength(MOCK_MESSAGES.length);
  });

  it('does not remove a deleted message if the request fails', async () => {
    createComponent();
    const { id, delete_path } = MOCK_MESSAGES[0];
    axiosMock.onDelete(delete_path).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

    findTable().vm.$emit('delete-message', id);
    await waitForPromises();

    expect(
      findTable()
        .props('messages')
        .find((m) => m.id.id === id.id),
    ).not.toBeUndefined();
    expect(createAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        message: BroadcastMessagesBase.i18n.deleteError,
      }),
    );
  });

  it('removes a deleted message from visibleMessages on success', async () => {
    createComponent();
    const { id, delete_path } = MOCK_MESSAGES[0];
    axiosMock.onDelete(delete_path).replyOnce(HTTP_STATUS_OK);

    findTable().vm.$emit('delete-message', id);
    await waitForPromises();

    expect(
      findTable()
        .props('messages')
        .find((m) => m.id.id === id.id),
    ).toBeUndefined();
    expect(findPagination().props('totalItems')).toBe(MOCK_MESSAGES.length - 1);
  });

  it('redirects to the first page when totalMessages changes from 21 to 20', async () => {
    window.location.pathname = `${TEST_HOST}/admin/broadcast_messages`;

    const messages = generateMockMessages(21);
    const { id, delete_path } = messages[0];
    createComponent({ messages, messagesCount: messages.length });

    axiosMock.onDelete(delete_path).replyOnce(HTTP_STATUS_OK);

    findTable().vm.$emit('delete-message', id);
    await waitForPromises();

    expect(visitUrl).toHaveBeenCalledWith(`${TEST_HOST}/admin/broadcast_messages?page=1`);
  });
});
