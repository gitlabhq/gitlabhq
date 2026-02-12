import { GlDrawer } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
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
import diffsEventHub from '~/diffs/event_hub';
import { useNotes } from '~/notes/store/legacy_notes';
import { useBatchComments } from '~/batch_comments/store';
import markdownEditorEventHub from '~/vue_shared/components/markdown/eventhub';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { CLEAR_AUTOSAVE_ENTRY_EVENT } from '~/vue_shared/constants';
import userCanApproveQuery from '~/batch_comments/queries/can_approve.query.graphql';
import toast from '~/vue_shared/plugins/global_toast';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

jest.mock('~/vue_shared/plugins/global_toast');

jest.mock('~/autosave');
jest.mock('~/vue_shared/components/markdown/eventhub');

Vue.use(PiniaVuePlugin);
Vue.use(VueApollo);

describe('ReviewDrawer', () => {
  let wrapper;
  let pinia;
  let trackingSpy;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findDrawerHeading = () => wrapper.findByTestId('reviewer-drawer-heading');
  const findCommentTextarea = () => wrapper.findByTestId('comment-textarea');
  const findSubmitButton = () => wrapper.findByTestId('submit-review-button');
  const findForm = () => wrapper.findByTestId('submit-gl-form');
  const findPlaceholderField = () => wrapper.findByTestId('placeholder-input-field');
  const findDiscardReviewButton = () => wrapper.findByTestId('discard-review-btn');
  const findDiscardReviewModal = () => wrapper.findByTestId('discard-review-modal');
  const findMarkdownField = () => wrapper.findComponent(MarkdownField);

  const submitForm = async () => {
    await findPlaceholderField().vm.$emit('focus');

    await findCommentTextarea().setValue('Hello world');

    await findForm().vm.$emit('submit', { preventDefault: jest.fn() });
  };

  const createComponent = ({ canApprove = true, diffsPath = '' } = {}) => {
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
    wrapper = mountExtended(ReviewDrawer, {
      pinia,
      apolloProvider,
      provide: {
        diffsPath,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia({
      plugins: [globalAccessorPlugin],
    });
    useLegacyDiffs().projectPath = 'gitlab-org/gitlab';
    useNotes().noteableData.id = 1;
    useNotes().noteableData.preview_note_path = '/preview';
    useNotes().noteableData.noteableType = 'merge_request';
    useNotes().notesData.markdownDocsPath = '/markdown/docs';
    useNotes().notesData.quickActionsDocsPath = '/quickactions/docs';
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

  describe.each`
    fileByFileMode | description   | goToFileCalls
    ${true}        | ${'enabled'}  | ${1}
    ${false}       | ${'disabled'} | ${0}
  `(
    'when clicking a draft with file by file mode $description',
    ({ fileByFileMode, goToFileCalls }) => {
      const diffsPath = 'http://gitlab.com/project/-/merge_requests/1/diffs';

      beforeEach(() => {
        useLegacyDiffs().viewDiffsFileByFile = fileByFileMode;
        useBatchComments().drawerOpened = true;
      });

      it('scrolls to draft when draft is on latest diff', async () => {
        const draft = { id: 1, file_path: 'foo' };
        useBatchComments().drafts = [draft];
        createComponent({ diffsPath });

        await wrapper.findComponent(PreviewItem).vm.$emit('click', draft);

        expect(useLegacyDiffs().goToFile).toHaveBeenCalledTimes(goToFileCalls);
        expect(useBatchComments().scrollToDraft).toHaveBeenCalledWith(draft);
      });

      it('navigates to commit URL when draft is not on latest diff', async () => {
        const draft = { id: 1, file_path: 'foo', position: { head_sha: 'old-sha' } };
        useNotes().noteableData.diff_head_sha = 'current-sha';
        useBatchComments().drafts = [draft];
        createComponent({ diffsPath });

        await wrapper.findComponent(PreviewItem).vm.$emit('click', draft);

        expect(useLegacyDiffs().goToFile).not.toHaveBeenCalled();
        expect(visitUrl).toHaveBeenCalledWith(expect.stringContaining('commit_id=old-sha'));
        expect(visitUrl).toHaveBeenCalledWith(expect.stringContaining('#draft_1'));
      });
    },
  );

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
    useNotes().discussions = [
      { id: 1, notes: [{ id: 1, userData: {}, author: { id: useNotes().userData.id } }] },
    ];
    window.mrTabs = { tabShown: jest.fn() };

    useBatchComments().drawerOpened = true;

    createComponent();

    await submitForm();

    await waitForPromises();

    useNotes().discussions[0].notes[0].id = 2;

    await nextTick();

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

  it('emits approval event when submitting with approved state', async () => {
    jest.spyOn(diffsEventHub, '$emit');

    useBatchComments().drawerOpened = true;
    useBatchComments().drafts = [{ id: 1 }];

    createComponent();

    await waitForPromises();
    await findPlaceholderField().vm.$emit('focus');
    await wrapper.find('.custom-control-input[value="approved"]').trigger('change');

    findCommentTextarea().setValue('Looks good');
    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    await waitForPromises();

    expect(diffsEventHub.$emit).toHaveBeenCalledWith('mr:reviewDrawer:submit:approval', {
      summary: true,
      comments: 1,
    });
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

  describe('when discarding a review', () => {
    beforeEach(() => {
      useBatchComments().drawerOpened = true;
      useBatchComments().drafts = [{ id: 1, file_path: 'foo' }];
    });

    it('shows modal when clicking discard button', async () => {
      createComponent();

      expect(findDiscardReviewModal().exists()).toBe(false);

      findDiscardReviewButton().vm.$emit('click');

      await nextTick();

      expect(findDiscardReviewModal().props('visible')).toBe(true);
    });

    it('calls discardReviews when primary action on modal is triggered', async () => {
      createComponent();

      findDiscardReviewButton().vm.$emit('click');

      await nextTick();

      findDiscardReviewModal().vm.$emit('primary');

      expect(useBatchComments().discardDrafts).toHaveBeenCalled();
    });

    it('creates a toast message when finished', async () => {
      createComponent();

      findDiscardReviewButton().vm.$emit('click');

      await nextTick();

      findDiscardReviewModal().vm.$emit('primary');

      await nextTick();

      expect(toast).toHaveBeenCalledWith('Review discarded');
    });

    it('calls setDrawerOpened when primary action on modal is triggered', async () => {
      createComponent();

      findDiscardReviewButton().vm.$emit('click');

      await nextTick();

      findDiscardReviewModal().vm.$emit('primary');

      await nextTick();

      expect(useBatchComments().setDrawerOpened).toHaveBeenCalledWith(false);
    });
  });

  it('calls publishReview when drafts count is 0', async () => {
    useBatchComments().drafts = [];

    useBatchComments().drawerOpened = true;

    createComponent();

    await waitForPromises();

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(useBatchComments().publishReview).toHaveBeenCalled();
  });

  it('calls publishReviewInBatches when drafts count is more than 0', async () => {
    useBatchComments().drafts = new Array(1).fill({});

    useBatchComments().drawerOpened = true;

    createComponent();

    await waitForPromises();

    findForm().vm.$emit('submit', { preventDefault: jest.fn() });

    expect(useBatchComments().publishReviewInBatches).toHaveBeenCalled();
  });

  it('disables table of contents support in the markdown editor', async () => {
    useBatchComments().drawerOpened = true;

    createComponent();

    await findPlaceholderField().vm.$emit('focus');

    expect(findMarkdownField().props('supportsTableOfContents')).toBe(false);
  });
});
