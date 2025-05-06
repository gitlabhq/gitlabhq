import { GlDrawer } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { mockTracking } from 'helpers/tracking_helper';
import ReviewDrawer from '~/batch_comments/components/review_drawer.vue';
import PreviewItem from '~/batch_comments/components/preview_item.vue';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import userCanApproveQuery from '~/batch_comments/queries/can_approve.query.graphql';

jest.mock('~/autosave');
jest.mock('~/vue_shared/components/markdown/eventhub');

Vue.use(PiniaVuePlugin);
Vue.use(Vuex);
Vue.use(VueApollo);

describe('ReviewDrawer', () => {
  let wrapper;
  let pinia;
  let trackingSpy;
  let getCurrentUserLastNote;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findDrawerHeading = () => wrapper.findByTestId('reviewer-drawer-heading');
  const findCommentTextarea = () => wrapper.findByTestId('comment-textarea');
  const findSubmitButton = () => wrapper.findByTestId('submit-review-button');
  const findForm = () => wrapper.findByTestId('submit-gl-form');
  const findPlaceholderField = () => wrapper.findByTestId('placeholder-input-field');

  const submitForm = async () => {
    await findPlaceholderField().vm.$emit('focus');

    await findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });
  };

  const createComponent = ({ canApprove = true } = {}) => {
    getCurrentUserLastNote = Vue.observable({ id: 1 });

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
        getDiscussion: () => jest.fn(),
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

    trackingSpy = mockTracking(undefined, null, jest.spyOn);
    wrapper = mountExtended(ReviewDrawer, { pinia, store, apolloProvider });
  };

  beforeEach(() => {
    pinia = createTestingPinia({
      plugins: [globalAccessorPlugin],
    });
    useLegacyDiffs();
    useNotes();
    useBatchComments();
  });

  it('shows drawer', () => {
    useBatchComments().drawerOpened = true;
    createComponent();
    expect(findDrawer().props('open')).toBe(true);
  });

  it('hides drawer', () => {
    createComponent();
    findDrawer().vm.$emit('close');
    expect(useBatchComments().setDrawerOpened).toHaveBeenCalledWith(false);
  });

  describe.each`
    draftsCount | heading
    ${0}        | ${'No pending comments'}
    ${1}        | ${'1 pending comment'}
    ${2}        | ${'2 pending comments'}
  `('with draftsCount as $draftsCount', ({ draftsCount, heading }) => {
    it(`renders heading as ${heading}`, () => {
      useBatchComments().drafts = new Array(draftsCount).fill({});
      useBatchComments().drawerOpened = true;
      createComponent();
      expect(findDrawerHeading().text()).toBe(heading);
    });
  });

  it('renders list of preview items', () => {
    useBatchComments().drafts = [{ id: 1 }, { id: 2 }];
    useBatchComments().drawerOpened = true;
    createComponent();

    const previewItems = wrapper.findAllComponents(PreviewItem);

    expect(previewItems).toHaveLength(2);
    expect(previewItems.at(0).props()).toMatchObject(expect.objectContaining({ draft: { id: 1 } }));
    expect(previewItems.at(1).props()).toMatchObject(expect.objectContaining({ draft: { id: 2 } }));
  });

  it('goes to a selected draft in file by file mode', async () => {
    const draft = { id: 1, file_path: 'foo' };
    useLegacyDiffs().viewDiffsFileByFile = true;
    useBatchComments().drafts = [draft];
    useBatchComments().drawerOpened = true;
    createComponent();

    await wrapper.findComponent(PreviewItem).vm.$emit('click', draft);

    expect(useLegacyDiffs().goToFile).toHaveBeenCalledWith({ path: draft.file_path });
  });

  it('calls publishReview with note data', async () => {
    useBatchComments().drawerOpened = true;

    createComponent();

    await submitForm();

    expect(useBatchComments().publishReview).toHaveBeenCalledWith(
      expect.objectContaining({
        note: 'Hello world',
        approve: false,
        reviewer_state: 'reviewed',
      }),
    );
  });

  it('emits CLEAR_AUTOSAVE_ENTRY_EVENT with autosave key', async () => {
    useBatchComments().drawerOpened = true;

    createComponent();

    await findPlaceholderField().vm.$emit('focus');

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    await waitForPromises();

    expect(markdownEditorEventHub.$emit).toHaveBeenCalledWith(
      CLEAR_AUTOSAVE_ENTRY_EVENT,
      'submit_review_dropdown/1',
    );
  });

  it('clears textarea value', async () => {
    useBatchComments().drawerOpened = true;

    createComponent();

    await findPlaceholderField().vm.$emit('focus');

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    await waitForPromises();

    expect(findCommentTextarea().element.value).toBe('');
  });

  it('tracks submit action', async () => {
    useBatchComments().drawerOpened = true;

    createComponent();

    await findPlaceholderField().vm.$emit('focus');

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
      label: 'markdown_editor',
      property: 'MergeRequest_review',
    });
  });

  it('switches to the overview tab after submit', async () => {
    window.mrTabs = { tabShown: jest.fn() };

    useBatchComments().drawerOpened = true;

    createComponent();

    await submitForm();

    await waitForPromises();

    getCurrentUserLastNote.id = 2;

    await Vue.nextTick();

    expect(window.mrTabs.tabShown).toHaveBeenCalledWith('show');
  });

  it('sets submit dropdown to loading', async () => {
    useBatchComments().drawerOpened = true;

    createComponent();

    await submitForm();

    expect(findSubmitButton().props('loading')).toBe(true);
  });

  it.each`
    value
    ${'approved'}
    ${'reviewed'}
    ${'requested_changes'}
  `('sends $value review state to api when submitting', async ({ value }) => {
    useBatchComments().drawerOpened = true;

    createComponent();

    await waitForPromises();

    await findPlaceholderField().vm.$emit('focus');

    await wrapper.find(`.custom-control-input[value="${value}"]`).trigger('change');

    findCommentTextarea().setValue('Hello world');

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(useBatchComments().publishReview).toHaveBeenCalledWith(
      expect.objectContaining({
        reviewer_state: value,
      }),
    );
  });

  it.each`
    canApprove | exists        | existsText
    ${true}    | ${undefined}  | ${'shows'}
    ${false}   | ${'disabled'} | ${'hides'}
  `(
    '$existsText approve checkbox if can_approve is $canApprove',
    async ({ canApprove, exists }) => {
      useBatchComments().drawerOpened = true;

      createComponent({ canApprove });

      await findPlaceholderField().vm.$emit('focus');

      await waitForPromises();

      expect(wrapper.findAll('input').at(1).attributes('disabled')).toBe(exists);
    },
  );
});
