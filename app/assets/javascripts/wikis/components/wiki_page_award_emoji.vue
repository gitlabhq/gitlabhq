<script>
import { produce } from 'immer';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import wikiPageQuery from '~/wikis/graphql/wiki_page.query.graphql';
import wikiPageToggleAwardEmojiMutation from '~/wikis/graphql/wiki_page_toggle_award_emoji.mutation.graphql';
import wikiPageSubscribeMutation from '~/wikis/graphql/wiki_page_subscribe.mutation.graphql';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

export default {
  name: 'WikiPageAwardEmoji',
  defaultAwards: [EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN],
  components: { AwardsList },
  inject: ['currentUserData', 'queryVariables'],
  props: {
    awards: {
      type: Array,
      required: true,
    },
    noteableId: {
      type: String,
      required: true,
    },
    canAwardEmoji: {
      type: Boolean,
      required: true,
    },
    isSubscribed: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    currentUserId() {
      return this.currentUserData?.id ?? null;
    },
    mappedAwards() {
      return this.awards.map((award) => ({
        ...award,
        user: {
          ...award.user,
          id: parseInt(getIdFromGraphQLId(award.user.id), 10),
        },
      }));
    },
  },
  methods: {
    isEmojiPresentForCurrentUser(name) {
      if (!this.currentUserId) return false;

      return this.awards.some(
        (emoji) => emoji.name === name && getIdFromGraphQLId(emoji.user.id) === this.currentUserId,
      );
    },
    addAwardEmoji(name) {
      if (!this.currentUserId || this.isEmojiPresentForCurrentUser(name)) return this.awards;

      return [
        ...this.awards,
        {
          name,
          __typename: 'AwardEmoji',
          user: {
            id: convertToGraphQLId(TYPENAME_USER, this.currentUserData.id),
            name: this.currentUserData.name,
            __typename: 'UserCore',
          },
        },
      ];
    },
    removeAwardEmoji(name) {
      if (!this.currentUserId) return this.awards;

      return this.awards.filter(
        (emoji) =>
          !(emoji.name === name && getIdFromGraphQLId(emoji.user.id) === this.currentUserId),
      );
    },
    handleAward(name) {
      this.$apollo
        .mutate({
          mutation: wikiPageToggleAwardEmojiMutation,
          variables: { name, awardableId: this.noteableId },
          optimisticResponse: {
            awardEmojiToggle: {
              errors: [],
              toggledOn: !this.isEmojiPresentForCurrentUser(name),
            },
          },
          update: (cache, { data }) => {
            const { toggledOn } = data.awardEmojiToggle;
            const query = { query: wikiPageQuery, variables: this.queryVariables };
            const sourceData = cache.readQuery(query);
            if (!sourceData) return;

            const newData = produce(sourceData, (draft) => {
              draft.wikiPage.awardEmoji.nodes = toggledOn
                ? this.addAwardEmoji(name)
                : this.removeAwardEmoji(name);
            });

            cache.writeQuery({ ...query, data: newData });
          },
        })
        .then(({ data }) => {
          if (data?.awardEmojiToggle?.toggledOn && !this.isSubscribed) {
            this.subscribeToPage();
          }
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
    subscribeToPage() {
      this.$apollo
        .mutate({
          mutation: wikiPageSubscribeMutation,
          variables: { id: this.noteableId, subscribed: true },
          optimisticResponse: {
            wikiPageSubscribe: {
              errors: [],
              wikiPage: {
                id: this.noteableId,
                subscribed: true,
              },
            },
          },
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
  },
};
</script>

<template>
  <awards-list
    :awards="mappedAwards"
    :can-award-emoji="canAwardEmoji"
    :current-user-id="currentUserId"
    :default-awards="$options.defaultAwards"
    @award="handleAward"
  />
</template>
