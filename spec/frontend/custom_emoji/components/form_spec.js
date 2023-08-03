import Vue, { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Form from '~/custom_emoji/components/form.vue';
import createCustomEmojiMutation from '~/custom_emoji/queries/create_custom_emoji.mutation.graphql';
import { CREATED_CUSTOM_EMOJI, CREATED_CUSTOM_EMOJI_WITH_ERROR } from '../mock_data';

let wrapper;
let createCustomEmojiResponseSpy;

function createMockApolloProvider(response) {
  Vue.use(VueApollo);

  createCustomEmojiResponseSpy = jest.fn().mockResolvedValue(response);

  const requestHandlers = [[createCustomEmojiMutation, createCustomEmojiResponseSpy]];

  return createMockApollo(requestHandlers);
}

function createComponent(response = CREATED_CUSTOM_EMOJI) {
  const mockApollo = createMockApolloProvider(response);

  return mountExtended(Form, {
    provide: {
      groupPath: 'gitlab-org',
    },
    apolloProvider: mockApollo,
  });
}

const findCustomEmojiNameInput = () => wrapper.findByTestId('custom-emoji-name-input');
const findCustomEmojiNameFormGroup = () => wrapper.findByTestId('custom-emoji-name-form-group');
const findCustomEmojiUrlInput = () => wrapper.findByTestId('custom-emoji-url-input');
const findCustomEmojiUrlFormGroup = () => wrapper.findByTestId('custom-emoji-url-form-group');
const findCustomEmojiFrom = () => wrapper.findByTestId('custom-emoji-form');
const findAlerts = () => wrapper.findAllComponents(GlAlert);
const findSubmitBtn = () => wrapper.findByTestId('custom-emoji-form-submit-btn');

function completeForm() {
  findCustomEmojiNameInput().setValue('Test');
  findCustomEmojiUrlInput().setValue('https://example.com');
  findCustomEmojiFrom().trigger('submit');
}

describe('Custom emoji form component', () => {
  describe('creates custom emoji', () => {
    it('calls apollo mutation', async () => {
      wrapper = createComponent();

      completeForm();

      await waitForPromises();

      expect(createCustomEmojiResponseSpy).toHaveBeenCalledWith({
        groupPath: 'gitlab-org',
        url: 'https://example.com',
        name: 'Test',
      });
    });

    it('does not submit when form validation fails', async () => {
      wrapper = createComponent();

      findCustomEmojiFrom().trigger('submit');

      await waitForPromises();

      expect(createCustomEmojiResponseSpy).not.toHaveBeenCalled();
    });

    it.each`
      findFormGroup                   | findInput                   | fieldName
      ${findCustomEmojiNameFormGroup} | ${findCustomEmojiUrlInput}  | ${'name'}
      ${findCustomEmojiUrlFormGroup}  | ${findCustomEmojiNameInput} | ${'URL'}
    `('shows errors for empty $fieldName input', async ({ findFormGroup, findInput }) => {
      wrapper = createComponent(CREATED_CUSTOM_EMOJI_WITH_ERROR);

      findInput().setValue('Test');
      findCustomEmojiFrom().trigger('submit');

      await waitForPromises();

      expect(findFormGroup().classes('is-invalid')).toBe(true);
    });

    it('displays errors when mutation fails', async () => {
      wrapper = createComponent(CREATED_CUSTOM_EMOJI_WITH_ERROR);

      completeForm();

      await waitForPromises();

      const alertMessages = findAlerts().wrappers.map((x) => x.text());

      expect(alertMessages).toEqual(CREATED_CUSTOM_EMOJI_WITH_ERROR.data.createCustomEmoji.errors);
    });

    it('shows loading state when saving', async () => {
      wrapper = createComponent();

      completeForm();

      await nextTick();

      expect(findSubmitBtn().props('loading')).toBe(true);

      await waitForPromises();

      expect(findSubmitBtn().props('loading')).toBe(false);
    });
  });
});
