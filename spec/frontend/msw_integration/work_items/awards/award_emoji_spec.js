import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initEmojiMock, clearEmojiMock } from 'helpers/emoji';
import { isLoggedIn } from '~/lib/utils/common_utils';
import WorkItemsRoot from '~/work_items/components/app.vue';
import { createRouter } from '~/work_items/router';
import { apolloProvider } from '~/graphql_shared/issuable_client';
import { workItemsRestResolver } from 'ee_else_ce/work_items/list/graphql/rest/work_items_rest_resolver';
import { findNotesWidget } from '~/work_items/utils';
import { createGraphQLResolver } from 'jest/msw_integration/work_items/resolver_utils';
import { findIssueToEdit, selectIssue } from 'jest/msw_integration/work_items/test_helpers';
import {
  namespaceWorkItemResponse,
  workItemNotesByIidResponse,
  resetAwardState,
} from 'jest/msw_integration/work_items/handlers';
import { server } from 'jest/msw_integration/server';

// The emoji picker selects reactions through a lazily-rendered virtual list
// (gl-intersection-observer @appear), which does not fire in jsdom. Examples that
// pick an emoji from the picker therefore stay in the Capybara spec; this suite
// covers everything else: toggling existing/default reactions and the
// permission-driven states (archived, locked, logged out).

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  isLoggedIn: jest.fn().mockReturnValue(true),
}));

// issuable_client.js evaluates window.gon.features at import time (before tests run),
// so the REST resolver is not registered automatically. Register it dynamically so the
// work item list renders clickable cards (the drawer is opened by clicking one).
apolloProvider.defaultClient.addResolvers({
  Namespace: { workItems: workItemsRestResolver },
});

Vue.use(VueApollo);

const FULL_PATH = 'gitlab-org/gitlab';

// Emoji data seeded via initEmojiMock so the picker can render/search the
// reactions the migrated examples exercise (defaults + the fixture reactions).
const AWARD_EMOJI_DATA = [
  { n: 'thumbsup', e: '👍', u: '6.0', c: 'people', d: 'thumbs up' },
  { n: 'thumbsdown', e: '👎', u: '6.0', c: 'people', d: 'thumbs down' },
  { n: '100', e: '💯', u: '6.0', c: 'symbols', d: 'hundred points' },
  { n: 'grinning', e: '😀', u: '6.1', c: 'people', d: 'grinning face' },
  { n: 'laughing', e: '😆', u: '6.0', c: 'people', d: 'grinning squinting face' },
  { n: 'raised_hand', e: '✋', u: '6.0', c: 'people', d: 'raised hand' },
];

const clone = (value) => JSON.parse(JSON.stringify(value));

const firstNote = (notesResponse) =>
  findNotesWidget(notesResponse.data.namespace.workItem).discussions.nodes[0].notes.nodes[0];

/**
 * Base work item query response (shell). Drives the body reaction component's
 * `canAwardEmoji`: `archived` and the NOTES widget's `discussionLocked` (which
 * work_item_detail reads from THIS query, not the notes query). Same WorkItem
 * entity as every other detail query.
 */
const namespaceWorkItemFixture = ({ archived = false, locked = false } = {}) => {
  const response = clone(namespaceWorkItemResponse);
  response.data.namespace.workItem.archived = archived;
  findNotesWidget(response.data.namespace.workItem).discussionLocked = locked;
  return response;
};

/**
 * Notes query response with one note. Flags flip only permission/lock state; the
 * note reaction data itself comes from Rails.
 * @param {boolean} locked - discussionLocked on the NOTES widget.
 * @param {boolean} canAward - the note's userPermissions.awardEmoji.
 * @param {boolean} withReaction - keep the fixture's 😀 reaction, or strip it.
 */
const awardEmojiNotesFixture = ({ locked = false, canAward = true, withReaction = true } = {}) => {
  const response = clone(workItemNotesByIidResponse);
  const notesWidget = findNotesWidget(response.data.namespace.workItem);
  notesWidget.discussionLocked = locked;

  const note = firstNote(response);
  note.userPermissions.awardEmoji = canAward;
  if (!withReaction) {
    note.awardEmoji.nodes = [];
  }
  return response;
};

// The work item opens in the drawer, which renders into the contextual panel
// portal, so all reaction lookups are scoped to that portal.
const drawer = () => document.getElementById('contextual-panel-portal');

const bodyAwardsBlock = () =>
  [...(drawer()?.querySelectorAll('.awards') ?? [])].find(
    (el) => !el.closest('[data-testid="note-wrapper"]'),
  ) ?? null;

const findNoteWrapper = () => drawer()?.querySelector('[data-testid="note-wrapper"]') ?? null;

const noteAwardsBlock = () => findNoteWrapper()?.querySelector('.awards') ?? null;

const awardButtonIn = (container, name) =>
  container?.querySelector(`[data-testid="award-button"][data-emoji-name="${name}"]`) ?? null;

const findBodyAwardButton = (name) => awardButtonIn(bodyAwardsBlock(), name);
const findNoteAwardButton = (name) => awardButtonIn(noteAwardsBlock(), name);

const awardCount = (button) => Number(button?.querySelector('.js-counter')?.textContent ?? 0);

const findBodyAddReactionButton = () =>
  bodyAwardsBlock()?.querySelector('[data-testid="add-reaction-button"]') ?? null;

const findNoteAddReactionButton = () =>
  noteAwardsBlock()?.querySelector('[data-testid="add-reaction-button"]') ?? null;

describe('Work item award emoji reactions', () => {
  const router = assignRouter(createRouter, { fullPath: FULL_PATH, routerPath: 'work_items' });

  // Overrides map onto the app's real operation names; award data itself comes
  // from the Rails-generated fixtures. We mount the work item list and open the
  // work item by clicking its card (which opens the drawer), rather than pushing
  // a route, to exercise the real navigation path.
  const mountWorkItemDrawer = async (overrides = {}) => {
    if (Object.keys(overrides).length > 0) {
      server.use(createGraphQLResolver(overrides));
    }

    fullMount(WorkItemsRoot, {
      router,
      propsData: { rootPageFullPath: FULL_PATH },
      apolloProvider,
      provide: {
        isGroup: false,
        isGroupIssuesList: false,
        fullPath: FULL_PATH,
        groupPath: 'gitlab-org',
        workItemType: 'Issue',
        isSignedIn: true,
        initialSort: 'created_desc',
        isServiceDeskSupported: false,
        glFeatures: {
          notificationsTodosButtons: true,
          workItemRestApiFrontendUsers: true,
          workItemRestApiIndex: true,
        },
      },
    });

    await waitForElement(findIssueToEdit);
    await selectIssue();
  };

  let originalGon;

  beforeAll(() => {
    createPortalElement();
    originalGon = window.gon;
  });

  beforeEach(async () => {
    resetAwardState();
    isLoggedIn.mockReturnValue(true);
    window.gon = {
      ...window.gon,
      api_version: 'v4',
      current_user_id: 16,
      current_user_fullname: 'Test User',
    };
    await initEmojiMock(AWARD_EMOJI_DATA);
    await apolloProvider.defaultClient.cache.reset();
  });

  afterEach(() => {
    clearEmojiMock();
    window.gon = originalGon;
  });

  describe('reactions on the work item body', () => {
    // The default fixture carries a 💯 reaction; waiting for its button signals the
    // query resolved before we interact (the optimistic cache update needs the query
    // cached first, otherwise it reads an empty cache and rolls back).
    beforeEach(async () => {
      await mountWorkItemDrawer();
      await waitForElement(() => findBodyAwardButton('100'));
    });

    it('toggles the thumbsup reaction on and off', async () => {
      const thumbsup = () => findBodyAwardButton('thumbsup');
      expect(awardCount(thumbsup())).toBe(0);

      thumbsup().click();
      await waitForAssertion(() => expect(awardCount(thumbsup())).toBe(1));

      thumbsup().click();
      await waitForAssertion(() => expect(awardCount(thumbsup())).toBe(0));

      thumbsup().click();
      await waitForAssertion(() => expect(awardCount(thumbsup())).toBe(1));
    });
  });

  describe('reactions on a note', () => {
    beforeEach(async () => {
      await mountWorkItemDrawer();
      await waitForElement(() => findNoteAwardButton('grinning'));
    });

    it('shows an existing reaction on the note', () => {
      expect(awardCount(findNoteAwardButton('grinning'))).toBe(1);
    });

    it('adds the current user vote to an existing note reaction', async () => {
      findNoteAwardButton('grinning').click();

      await waitForAssertion(() => expect(awardCount(findNoteAwardButton('grinning'))).toBe(2));
    });
  });

  describe('when reactions are not permitted', () => {
    describe('in an archived project', () => {
      beforeEach(async () => {
        await mountWorkItemDrawer({
          namespaceWorkItem: namespaceWorkItemFixture({ archived: true }),
        });
        await waitForElement(() => findBodyAwardButton('100'));
      });

      it('hides reaction controls and blocks toggling', async () => {
        await waitForAssertion(() => {
          expect(findBodyAddReactionButton()).toBe(null);
          expect(findNoteAddReactionButton()).toBe(null);
        });

        findBodyAwardButton('100').click();
        await waitForAssertion(() => expect(awardCount(findBodyAwardButton('100'))).toBe(1));
      });
    });

    describe('on a locked issue', () => {
      beforeEach(async () => {
        await mountWorkItemDrawer({
          namespaceWorkItem: namespaceWorkItemFixture({ locked: true }),
          workItemNotesByIid: awardEmojiNotesFixture({ locked: true }),
        });
        await waitForElement(() => findBodyAwardButton('100'));
      });

      it('hides reaction controls and blocks toggling', async () => {
        await waitForAssertion(() => expect(findBodyAddReactionButton()).toBe(null));

        findBodyAwardButton('100').click();
        await waitForAssertion(() => expect(awardCount(findBodyAwardButton('100'))).toBe(1));
      });
    });

    describe('when the note award permission is denied', () => {
      // The work item is NOT archived and NOT locked; only the note's own
      // userPermissions.awardEmoji is false, so it is the sole cause of the
      // hidden note control (removing canAward: false makes this test fail).
      beforeEach(async () => {
        await mountWorkItemDrawer({
          workItemNotesByIid: awardEmojiNotesFixture({ canAward: false }),
        });
        await waitForElement(() => findNoteAwardButton('grinning'));
      });

      it('shows the existing note reaction but blocks adding or toggling it', async () => {
        expect(awardCount(findNoteAwardButton('grinning'))).toBe(1);

        // The note cannot be reacted to, while the body still can — proving the
        // denied permission is scoped to the note, not a global page state.
        await waitForAssertion(() => {
          expect(findNoteAddReactionButton()).toBe(null);
          expect(findBodyAddReactionButton()).not.toBe(null);
        });

        findNoteAwardButton('grinning').click();
        await waitForAssertion(() => expect(awardCount(findNoteAwardButton('grinning'))).toBe(1));
      });
    });

    describe('for a logged-out user', () => {
      beforeEach(async () => {
        isLoggedIn.mockReturnValue(false);
        await mountWorkItemDrawer();
        await waitForElement(() => findBodyAwardButton('100'));
      });

      it('hides the reaction control', async () => {
        await waitForAssertion(() => expect(findBodyAddReactionButton()).toBe(null));
      });
    });
  });
});
