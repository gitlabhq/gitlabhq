import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createdSavedReplyResponse from 'test_fixtures/graphql/saved_replies/create_saved_reply.mutation.graphql.json';
import createdSavedReplyErrorResponse from 'test_fixtures/graphql/saved_replies/create_saved_reply_with_errors.mutation.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Form from '~/saved_replies/components/form.vue';
import createSavedReplyMutation from '~/saved_replies/queries/create_saved_reply.mutation.graphql';

let wrapper;
let createSavedReplyResponseSpy;

function createMockApolloProvider(response) {
  Vue.use(VueApollo);

  createSavedReplyResponseSpy = jest.fn().mockResolvedValue(response);

  const requestHandlers = [[createSavedReplyMutation, createSavedReplyResponseSpy]];

  return createMockApollo(requestHandlers);
}

function createComponent(response = createdSavedReplyResponse) {
  const mockApollo = createMockApolloProvider(response);

  return mount(Form, {
    apolloProvider: mockApollo,
  });
}

const findSavedReplyNameInput = () => wrapper.find('[data-testid="saved-reply-name-input"]');
const findSavedReplyNameFormGroup = () =>
  wrapper.find('[data-testid="saved-reply-name-form-group"]');
const findSavedReplyContentInput = () => wrapper.find('[data-testid="saved-reply-content-input"]');
const findSavedReplyContentFormGroup = () =>
  wrapper.find('[data-testid="saved-reply-content-form-group"]');
const findSavedReplyFrom = () => wrapper.find('[data-testid="saved-reply-form"]');
const findAlerts = () => wrapper.findAllComponents(GlAlert);
const findSubmitBtn = () => wrapper.find('[data-testid="saved-reply-form-submit-btn"]');

describe('Saved replies form component', () => {
  describe('create saved reply', () => {
    it('calls apollo mutation', async () => {
      wrapper = createComponent();

      findSavedReplyNameInput().setValue('Test');
      findSavedReplyContentInput().setValue('Test content');
      findSavedReplyFrom().trigger('submit');

      await waitForPromises();

      expect(createSavedReplyResponseSpy).toHaveBeenCalledWith({
        content: 'Test content',
        name: 'Test',
      });
    });

    it('does not submit when form validation fails', async () => {
      wrapper = createComponent();

      findSavedReplyFrom().trigger('submit');

      await waitForPromises();

      expect(createSavedReplyResponseSpy).not.toHaveBeenCalled();
    });

    it.each`
      findFormGroup                     | findInput                     | fieldName
      ${findSavedReplyNameFormGroup}    | ${findSavedReplyContentInput} | ${'name'}
      ${findSavedReplyContentFormGroup} | ${findSavedReplyNameInput}    | ${'content'}
    `('shows errors for empty $fieldName input', async ({ findFormGroup, findInput }) => {
      wrapper = createComponent(createdSavedReplyErrorResponse);

      findInput().setValue('Test');
      findSavedReplyFrom().trigger('submit');

      await waitForPromises();

      expect(findFormGroup().classes('is-invalid')).toBe(true);
    });

    it('displays errors when mutation fails', async () => {
      wrapper = createComponent(createdSavedReplyErrorResponse);

      findSavedReplyNameInput().setValue('Test');
      findSavedReplyContentInput().setValue('Test content');
      findSavedReplyFrom().trigger('submit');

      await waitForPromises();

      const { errors } = createdSavedReplyErrorResponse;
      const alertMessages = findAlerts().wrappers.map((x) => x.text());

      expect(alertMessages).toEqual(errors.map((x) => x.message));
    });

    it('shows loading state when saving', async () => {
      wrapper = createComponent();

      findSavedReplyNameInput().setValue('Test');
      findSavedReplyContentInput().setValue('Test content');
      findSavedReplyFrom().trigger('submit');

      await nextTick();

      expect(findSubmitBtn().props('loading')).toBe(true);

      await waitForPromises();

      expect(findSubmitBtn().props('loading')).toBe(false);
    });
  });
});
