import { GlDisclosureDropdown } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { PiniaVuePlugin } from 'pinia';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SubmitDropdown from '~/batch_comments/components/submit_dropdown.vue';
import { mockTracking } from 'helpers/tracking_helper';
import userCanApproveQuery from '~/batch_comments/queries/can_approve.query.graphql';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';

jest.mock('~/autosave');
jest.mock('~/vue_shared/components/markdown/eventhub');

Vue.use(VueApollo);
Vue.use(Vuex);
Vue.use(PiniaVuePlugin);

let wrapper;
let pinia;
let trackingSpy;
let getCurrentUserLastNote;

function factory({ canApprove = true, shouldAnimateReviewButton = false } = {}) {
  trackingSpy = mockTracking(undefined, null, jest.spyOn);
  const requestHandlers = [
    [
      userCanApproveQuery,
      () =>
        Promise.resolve({
          data: {
            project: {
              id: 1,
              mergeRequest: {
                id: 1,
                userPermissions: {
                  canApprove,
                },
              },
            },
          },
        }),
    ],
  ];
  const apolloProvider = createMockApollo(requestHandlers);
  getCurrentUserLastNote = Vue.observable({ id: 1 });

  useBatchComments().shouldAnimateReviewButton = shouldAnimateReviewButton;

  const store = new Vuex.Store({
    getters: {
      getNotesData: () => ({
        markdownDocsPath: '/markdown/docs',
        quickActionsDocsPath: '/quickactions/docs',
      }),
      getNoteableData: () => ({
        id: 1,
        preview_note_path: '/preview',
      }),
      noteableType: () => 'merge_request',
      getCurrentUserLastNote: () => getCurrentUserLastNote,
    },
    modules: {
      diffs: {
        namespaced: true,
        state: {
          projectPath: 'gitlab-org/gitlab',
        },
      },
    },
  });
  wrapper = mountExtended(SubmitDropdown, {
    store,
    pinia,
    apolloProvider,
  });
}

const findCommentTextarea = () => wrapper.findByTestId('comment-textarea');
const findSubmitButton = () => wrapper.findByTestId('submit-review-button');
const findForm = () => wrapper.findByTestId('submit-gl-form');
const findSubmitDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

describe('Batch comments submit dropdown', () => {
  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  afterEach(() => {
    window.mrTabs = null;
  });

  it('calls publishReview with note data', async () => {
    factory();

    await findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(useBatchComments().publishReview).toHaveBeenCalledWith({
      noteable_type: 'merge_request',
      noteable_id: 1,
      note: 'Hello world',
      approve: false,
      approval_password: '',
      reviewer_state: 'reviewed',
    });
  });

  it('emits CLEAR_AUTOSAVE_ENTRY_EVENT with autosave key', async () => {
    factory();

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    await waitForPromises();

    expect(markdownEditorEventHub.$emit).toHaveBeenCalledWith(
      CLEAR_AUTOSAVE_ENTRY_EVENT,
      'submit_review_dropdown/1',
    );
  });

  it('clears textarea value', async () => {
    factory();

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    await waitForPromises();

    expect(findCommentTextarea().element.value).toBe('');
  });

  it('tracks submit action', () => {
    factory();

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
      label: 'markdown_editor',
      property: 'MergeRequest_review',
    });
  });

  it('switches to the overview tab after submit', async () => {
    window.mrTabs = { tabShown: jest.fn() };

    factory();

    findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    await waitForPromises();

    getCurrentUserLastNote.id = 2;

    await Vue.nextTick();

    expect(window.mrTabs.tabShown).toHaveBeenCalledWith('show');
  });

  it('sets submit dropdown to loading', async () => {
    factory();

    findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(findSubmitButton().props('loading')).toBe(true);
  });

  it.each`
    canApprove | exists        | existsText
    ${true}    | ${undefined}  | ${'shows'}
    ${false}   | ${'disabled'} | ${'hides'}
  `(
    '$existsText approve checkbox if can_approve is $canApprove',
    async ({ canApprove, exists }) => {
      factory({ canApprove });

      wrapper.findComponent(GlDisclosureDropdown).vm.$emit('shown');

      await waitForPromises();

      expect(wrapper.findAll('input').at(1).attributes('disabled')).toBe(exists);
    },
  );

  it.each`
    shouldAnimateReviewButton | animationClassApplied | classText
    ${true}                   | ${true}               | ${'applies'}
    ${false}                  | ${false}              | ${'does not apply'}
  `(
    '$classText animation class to `Finish review` button if `shouldAnimateReviewButton` is $shouldAnimateReviewButton',
    ({ shouldAnimateReviewButton, animationClassApplied }) => {
      factory({ shouldAnimateReviewButton });

      expect(findSubmitDropdown().classes('submit-review-dropdown-animated')).toBe(
        animationClassApplied,
      );
    },
  );

  it('renders a radio group with review state options', async () => {
    factory();

    await waitForPromises();

    expect(wrapper.findAll('.gl-form-radio').length).toBe(3);
  });

  it('renders disabled approve radio button when user can not approve', async () => {
    factory({ mrRequestChanges: true, canApprove: false });

    wrapper.findComponent(GlDisclosureDropdown).vm.$emit('shown');

    await waitForPromises();

    expect(wrapper.find('.custom-control-input[value="approved"]').attributes('disabled')).toBe(
      'disabled',
    );
  });

  it.each`
    value
    ${'approved'}
    ${'reviewed'}
    ${'requested_changes'}
  `('sends $value review state to api when submitting', async ({ value }) => {
    factory();

    wrapper.findComponent(GlDisclosureDropdown).vm.$emit('shown');

    await waitForPromises();

    await wrapper.find(`.custom-control-input[value="${value}"]`).trigger('change');

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(useBatchComments().publishReview).toHaveBeenCalledWith({
      noteable_type: 'merge_request',
      noteable_id: 1,
      note: 'Hello world',
      approve: false,
      approval_password: '',
      reviewer_state: value,
    });
  });
});
