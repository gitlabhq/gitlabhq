import Vue from 'vue';
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import SubmitDropdown from '~/batch_comments/components/submit_dropdown.vue';

Vue.use(Vuex);

let wrapper;
let publishReview;

function factory() {
  publishReview = jest.fn();

  const store = new Vuex.Store({
    getters: {
      getNotesData: () => ({
        markdownDocsPath: '/markdown/docs',
        quickActionsDocsPath: '/quickactions/docs',
      }),
      getNoteableData: () => ({ id: 1, preview_note_path: '/preview' }),
      noteableType: () => 'merge_request',
    },
    modules: {
      batchComments: {
        namespaced: true,
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

describe('Batch comments submit dropdown', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('calls publishReview with note data', async () => {
    factory();

    findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(publishReview).toHaveBeenCalledWith(expect.anything(), {
      noteable_type: 'merge_request',
      noteable_id: 1,
      note: 'Hello world',
    });
  });

  it('sets submit dropdown to loading', async () => {
    factory();

    findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(findSubmitButton().props('loading')).toBe(true);
  });
});
