import Vue, { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createdSavedReplyResponse from 'test_fixtures/graphql/comment_templates/create_saved_reply.mutation.graphql.json';
import createdSavedReplyErrorResponse from 'test_fixtures/graphql/comment_templates/create_saved_reply_with_errors.mutation.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mockTracking } from 'helpers/tracking_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Form from '~/comment_templates/components/form.vue';
import createSavedReplyMutation from '~/pages/profiles/comment_templates/queries/create_saved_reply.mutation.graphql';
import updateSavedReplyMutation from '~/pages/profiles/comment_templates/queries/update_saved_reply.mutation.graphql';

let wrapper;
let createSavedReplyResponseSpy;
let updateSavedReplyResponseSpy;

function createMockApolloProvider(response) {
  Vue.use(VueApollo);

  createSavedReplyResponseSpy = jest.fn().mockResolvedValue(response);
  updateSavedReplyResponseSpy = jest.fn().mockResolvedValue(response);

  const requestHandlers = [
    [createSavedReplyMutation, createSavedReplyResponseSpy],
    [updateSavedReplyMutation, updateSavedReplyResponseSpy],
  ];

  return createMockApollo(requestHandlers);
}

function createComponent(id = null, response = createdSavedReplyResponse) {
  const mockApollo = createMockApolloProvider(response);

  return mount(Form, {
    propsData: {
      id,
    },
    provide: {
      createMutation: createSavedReplyMutation,
      updateMutation: updateSavedReplyMutation,
    },
    apolloProvider: mockApollo,
  });
}

const findSavedReplyNameInput = () => wrapper.find('[data-testid="comment-template-name-input"]');
const findSavedReplyNameFormGroup = () =>
  wrapper.find('[data-testid="comment-template-name-form-group"]');
const findSavedReplyContentInput = () =>
  wrapper.find('[data-testid="comment-template-content-input"]');
const findSavedReplyContentFormGroup = () =>
  wrapper.find('[data-testid="comment-template-content-form-group"]');
const findSavedReplyFrom = () => wrapper.find('[data-testid="comment-template-form"]');
const findAlerts = () => wrapper.findAllComponents(GlAlert);
const findSubmitBtn = () => wrapper.find('[data-testid="comment-template-form-submit-btn"]');

describe('Comment templates form component', () => {
  describe('creates comment template', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
    });

    it('calls apollo mutation', async () => {
      wrapper = createComponent();

      findSavedReplyNameInput().setValue('Test');
      findSavedReplyContentInput().setValue('Test content');
      findSavedReplyFrom().trigger('submit');

      await waitForPromises();

      expect(createSavedReplyResponseSpy).toHaveBeenCalledWith({
        id: null,
        content: 'Test content',
        name: 'Test',
        namespaceId: undefined,
      });
      expect(trackingSpy).toHaveBeenCalledWith(
        undefined,
        'i_code_review_saved_replies_create',
        expect.any(Object),
      );
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
      wrapper = createComponent(null, createdSavedReplyErrorResponse);

      findInput().setValue('Test');
      findSavedReplyFrom().trigger('submit');

      await waitForPromises();

      expect(findFormGroup().classes('is-invalid')).toBe(true);
    });

    it('displays errors when mutation fails', async () => {
      wrapper = createComponent(null, createdSavedReplyErrorResponse);

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

    it('shows markdown preview button', () => {
      wrapper = createComponent();

      expect(wrapper.text()).toContain('Preview');
    });

    it('allows switching to rich text editor', () => {
      wrapper = createComponent();

      expect(wrapper.text()).toContain('Switch to rich text editing');
    });
  });

  describe('updates saved reply', () => {
    it('calls apollo mutation', async () => {
      wrapper = createComponent('1');

      findSavedReplyNameInput().setValue('Test');
      findSavedReplyContentInput().setValue('Test content');
      findSavedReplyFrom().trigger('submit');

      await waitForPromises();

      expect(updateSavedReplyResponseSpy).toHaveBeenCalledWith({
        id: '1',
        content: 'Test content',
        name: 'Test',
        namespaceId: undefined,
      });
    });
  });
});
