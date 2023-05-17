import { GlDropdown } from '@gitlab/ui';
import Vue from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SubmitDropdown from '~/batch_comments/components/submit_dropdown.vue';

jest.mock('~/autosave');

Vue.use(Vuex);

let wrapper;
let publishReview;

function factory({ canApprove = true, shouldAnimateReviewButton = false } = {}) {
  publishReview = jest.fn();

  const store = new Vuex.Store({
    getters: {
      getNotesData: () => ({
        markdownDocsPath: '/markdown/docs',
        quickActionsDocsPath: '/quickactions/docs',
      }),
      getNoteableData: () => ({
        id: 1,
        preview_note_path: '/preview',
        current_user: { can_approve: canApprove },
      }),
      noteableType: () => 'merge_request',
      getCurrentUserLastNote: () => ({ id: 1 }),
    },
    modules: {
      batchComments: {
        namespaced: true,
        state: { shouldAnimateReviewButton },
        actions: {
          publishReview,
        },
      },
    },
  });
  wrapper = mountExtended(SubmitDropdown, {
    store,
  });
}

const findCommentTextarea = () => wrapper.findByTestId('comment-textarea');
const findSubmitButton = () => wrapper.findByTestId('submit-review-button');
const findForm = () => wrapper.findByTestId('submit-gl-form');
const findSubmitDropdown = () => wrapper.findComponent(GlDropdown);

describe('Batch comments submit dropdown', () => {
  afterEach(() => {
    window.mrTabs = null;
  });

  it('calls publishReview with note data', async () => {
    factory();

    findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(publishReview).toHaveBeenCalledWith(expect.anything(), {
      noteable_type: 'merge_request',
      noteable_id: 1,
      note: 'Hello world',
      approve: false,
      approval_password: '',
    });
  });

  it('switches to the overview tab after submit', async () => {
    window.mrTabs = { tabShown: jest.fn() };

    factory();

    findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });
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
    canApprove | exists   | existsText
    ${true}    | ${true}  | ${'shows'}
    ${false}   | ${false} | ${'hides'}
  `('$existsText approve checkbox if can_approve is $canApprove', ({ canApprove, exists }) => {
    factory({ canApprove });

    expect(wrapper.findByTestId('approve_merge_request').exists()).toBe(exists);
  });

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
});
