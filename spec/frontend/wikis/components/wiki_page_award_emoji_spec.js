import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import WikiPageAwardEmoji from '~/wikis/components/wiki_page_award_emoji.vue';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import wikiPageToggleAwardEmojiMutation from '~/wikis/graphql/wiki_page_toggle_award_emoji.mutation.graphql';
import wikiPageSubscribeMutation from '~/wikis/graphql/wiki_page_subscribe.mutation.graphql';
import { currentUserData, queryVariables } from '../notes/mock_data';

Vue.use(VueApollo);

const NOTEABLE_ID = 'gid://gitlab/WikiPage::Meta/1';
const CURRENT_USER_GID = 'gid://gitlab/User/70';

const buildWikiPageData = ({ awards = [], subscribed = false, canAwardEmoji = true } = {}) => ({
  wikiPage: {
    __typename: 'WikiPage',
    id: NOTEABLE_ID,
    title: 'home',
    subscribed,
    awardEmoji: { __typename: 'AwardEmojiConnection', nodes: awards },
    userPermissions: {
      __typename: 'WikiPagePermissions',
      markNoteAsInternal: true,
      awardEmoji: canAwardEmoji,
    },
    discussions: { __typename: 'DiscussionConnection', nodes: [] },
  },
});

const buildAward = (name, userId = CURRENT_USER_GID, userName = 'Tester1') => ({
  __typename: 'AwardEmoji',
  name,
  user: { __typename: 'UserCore', id: userId, name: userName },
});

describe('WikiPageAwardEmoji', () => {
  let wrapper;
  let queryHandler;
  let toggleHandler;
  let subscribeHandler;

  let apolloProvider;

  const createWrapper = async ({
    awards = [],
    subscribed = false,
    canAwardEmoji = true,
    toggleHandlerImpl,
    subscribeHandlerImpl,
    provideCurrentUserData = currentUserData,
  } = {}) => {
    queryHandler = jest.fn().mockResolvedValue({
      data: buildWikiPageData({ awards, subscribed, canAwardEmoji }),
    });
    toggleHandler =
      toggleHandlerImpl ||
      jest.fn().mockResolvedValue({
        data: {
          awardEmojiToggle: { __typename: 'AwardEmojiTogglePayload', errors: [], toggledOn: true },
        },
      });
    subscribeHandler =
      subscribeHandlerImpl ||
      jest.fn().mockResolvedValue({
        data: {
          wikiPageSubscribe: {
            __typename: 'WikiPageSubscribePayload',
            errors: [],
            wikiPage: { __typename: 'WikiPage', id: NOTEABLE_ID, subscribed: true },
          },
        },
      });

    apolloProvider = createMockApollo([
      [wikiPageQuery, queryHandler],
      [wikiPageToggleAwardEmojiMutation, toggleHandler],
      [wikiPageSubscribeMutation, subscribeHandler],
    ]);

    wrapper = shallowMountExtended(WikiPageAwardEmoji, {
      apolloProvider,
      propsData: {
        awards,
        noteableId: NOTEABLE_ID,
        canAwardEmoji,
        isSubscribed: subscribed,
      },
      provide: { currentUserData: provideCurrentUserData, queryVariables },
    });

    apolloProvider.defaultClient.cache.writeQuery({
      query: wikiPageQuery,
      variables: queryVariables,
      data: buildWikiPageData({ awards, subscribed, canAwardEmoji }),
    });

    await waitForPromises();
  };

  const readCacheAwards = () => {
    const data = apolloProvider.defaultClient.cache.readQuery({
      query: wikiPageQuery,
      variables: queryVariables,
    });
    return data?.wikiPage?.awardEmoji?.nodes || [];
  };

  const findAwardsList = () => wrapper.findComponent(AwardsList);

  describe('mappedAwards', () => {
    it('converts GraphQL user IDs to integers for AwardsList', async () => {
      await createWrapper({ awards: [buildAward('thumbsup')] });

      const passedAwards = findAwardsList().props('awards');
      expect(passedAwards[0].user.id).toBe(70);
    });
  });

  describe('when currentUserData is null (anonymous user)', () => {
    it('renders without error', async () => {
      await createWrapper({
        awards: [buildAward('thumbsup')],
        canAwardEmoji: false,
        provideCurrentUserData: null,
      });

      expect(findAwardsList().exists()).toBe(true);
    });

    it('passes null as currentUserId to AwardsList', async () => {
      await createWrapper({
        awards: [buildAward('thumbsup')],
        canAwardEmoji: false,
        provideCurrentUserData: null,
      });

      expect(findAwardsList().props('currentUserId')).toBeNull();
    });

    it('displays existing awards from other users', async () => {
      const otherUserAward = buildAward('thumbsup', 'gid://gitlab/User/99', 'OtherUser');
      await createWrapper({
        awards: [otherUserAward],
        canAwardEmoji: false,
        provideCurrentUserData: null,
      });

      const passedAwards = findAwardsList().props('awards');
      expect(passedAwards).toHaveLength(1);
      expect(passedAwards[0].name).toBe('thumbsup');
    });
  });

  describe('handleAward', () => {
    it('calls the toggle mutation with the correct variables', async () => {
      await createWrapper();
      findAwardsList().vm.$emit('award', 'thumbsup');
      await waitForPromises();

      expect(toggleHandler).toHaveBeenCalledWith({
        name: 'thumbsup',
        awardableId: NOTEABLE_ID,
      });
    });

    describe('when toggled on', () => {
      it('adds the emoji to the cache', async () => {
        await createWrapper();

        expect(readCacheAwards()).toHaveLength(0);

        findAwardsList().vm.$emit('award', 'thumbsup');
        await waitForPromises();

        const cachedAwards = readCacheAwards();
        expect(cachedAwards).toHaveLength(1);
        expect(cachedAwards[0].name).toBe('thumbsup');
      });
    });

    describe('when toggled off', () => {
      it('removes the emoji from the cache', async () => {
        await createWrapper({
          awards: [buildAward('thumbsup')],
          toggleHandlerImpl: jest.fn().mockResolvedValue({
            data: {
              awardEmojiToggle: {
                __typename: 'AwardEmojiTogglePayload',
                errors: [],
                toggledOn: false,
              },
            },
          }),
        });

        expect(readCacheAwards()).toHaveLength(1);

        findAwardsList().vm.$emit('award', 'thumbsup');
        await waitForPromises();

        expect(readCacheAwards()).toHaveLength(0);
      });
    });

    describe('when the mutation rejects', () => {
      it('captures the error in Sentry', async () => {
        const error = new Error('mutation failed');
        jest.spyOn(Sentry, 'captureException');
        await createWrapper({
          toggleHandlerImpl: jest.fn().mockRejectedValue(error),
        });

        findAwardsList().vm.$emit('award', 'thumbsup');
        await waitForPromises();

        expect(Sentry.captureException).toHaveBeenCalledWith(error);
      });
    });

    describe('subscription side effect', () => {
      describe('when the user is not subscribed', () => {
        it('auto-subscribes to the page', async () => {
          await createWrapper({ subscribed: false });
          findAwardsList().vm.$emit('award', 'thumbsup');
          await waitForPromises();

          expect(subscribeHandler).toHaveBeenCalledWith({
            id: NOTEABLE_ID,
            subscribed: true,
          });
        });
      });

      describe('when the user is already subscribed', () => {
        it('does not call subscribe', async () => {
          await createWrapper({ subscribed: true });
          findAwardsList().vm.$emit('award', 'thumbsup');
          await waitForPromises();

          expect(subscribeHandler).not.toHaveBeenCalled();
        });
      });

      describe('when toggled off', () => {
        it('does not call subscribe', async () => {
          await createWrapper({
            awards: [buildAward('thumbsup')],
            subscribed: false,
            toggleHandlerImpl: jest.fn().mockResolvedValue({
              data: {
                awardEmojiToggle: {
                  __typename: 'AwardEmojiTogglePayload',
                  errors: [],
                  toggledOn: false,
                },
              },
            }),
          });

          findAwardsList().vm.$emit('award', 'thumbsup');
          await waitForPromises();

          expect(subscribeHandler).not.toHaveBeenCalled();
        });
      });

      describe('when the subscribe mutation rejects', () => {
        it('captures the error in Sentry', async () => {
          const error = new Error('subscribe failed');
          jest.spyOn(Sentry, 'captureException');
          await createWrapper({
            subscribed: false,
            subscribeHandlerImpl: jest.fn().mockRejectedValue(error),
          });

          findAwardsList().vm.$emit('award', 'thumbsup');
          await waitForPromises();

          expect(Sentry.captureException).toHaveBeenCalledWith(error);
        });
      });
    });
  });
});
