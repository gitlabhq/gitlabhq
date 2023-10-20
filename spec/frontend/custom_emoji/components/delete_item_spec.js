import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import DeleteItem from '~/custom_emoji/components/delete_item.vue';
import deleteCustomEmojiMutation from '~/custom_emoji/queries/delete_custom_emoji.mutation.graphql';
import { CUSTOM_EMOJI } from '../mock_data';

jest.mock('~/alert');
jest.mock('~/sentry/sentry_browser_wrapper');

let wrapper;
let deleteMutationSpy;

Vue.use(VueApollo);

function createSuccessSpy() {
  deleteMutationSpy = jest.fn().mockResolvedValue({
    data: { destroyCustomEmoji: { customEmoji: { id: CUSTOM_EMOJI[0].id } } },
  });
}

function createErrorSpy() {
  deleteMutationSpy = jest.fn().mockRejectedValue();
}

function createMockApolloProvider() {
  const requestHandlers = [[deleteCustomEmojiMutation, deleteMutationSpy]];

  return createMockApollo(requestHandlers);
}

function createComponent() {
  const apolloProvider = createMockApolloProvider();

  wrapper = mountExtended(DeleteItem, {
    apolloProvider,
    propsData: {
      emoji: CUSTOM_EMOJI[0],
    },
  });
}

const findDeleteButton = () => wrapper.findByTestId('delete-button');
const findModal = () => wrapper.findComponent(GlModal);

describe('Custom emoji delete item component', () => {
  it('opens modal when clicking button', async () => {
    createSuccessSpy();
    createComponent();

    await findDeleteButton().trigger('click');

    expect(document.querySelector('.gl-modal')).not.toBe(null);
  });

  it('calls GraphQL mutation on modals primary action', () => {
    createSuccessSpy();
    createComponent();

    findModal().vm.$emit('primary');

    expect(deleteMutationSpy).toHaveBeenCalledWith({ id: CUSTOM_EMOJI[0].id });
  });

  it('creates alert when mutation fails', async () => {
    createErrorSpy();
    createComponent();

    findModal().vm.$emit('primary');
    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith('Failed to delete custom emoji. Please try again.');
  });

  it('calls sentry when mutation fails', async () => {
    createErrorSpy();
    createComponent();

    findModal().vm.$emit('primary');
    await waitForPromises();

    expect(Sentry.captureException).toHaveBeenCalled();
  });
});
