<script>
import { produce } from 'immer';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';

import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';
import projectWorkItemAwardEmojiQuery from '../graphql/award_emoji.query.graphql';
import updateAwardEmojiMutation from '../graphql/update_award_emoji.mutation.graphql';
import {
  WIDGET_TYPE_AWARD_EMOJI,
  DEFAULT_PAGE_SIZE_EMOJIS,
  I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR,
} from '../constants';

export default {
  defaultAwards: [EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN],
  isLoggedIn: isLoggedIn(),
  components: {
    AwardsList,
  },
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    workItemFullpath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  computed: {
    currentUserId() {
      return window.gon.current_user_id;
    },
    currentUserFullName() {
      return window.gon.current_user_fullname;
    },
    /**
     * Parse and convert emoji reactions list to a format that AwardsList can understand
     */
    awards() {
      if (!this.awardEmoji) {
        return [];
      }

      return this.awardEmoji.nodes.map((emoji) => ({
        name: emoji.name,
        user: {
          id: getIdFromGraphQLId(emoji.user.id),
          name: emoji.user.name,
        },
      }));
    },
    pageInfo() {
      return this.awardEmoji?.pageInfo;
    },
    hasNextPage() {
      return this.pageInfo?.hasNextPage;
    },
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    awardEmoji: {
      query: projectWorkItemAwardEmojiQuery,
      variables() {
        return {
          iid: this.workItemIid,
          fullPath: this.workItemFullpath,
          after: this.after,
          pageSize: DEFAULT_PAGE_SIZE_EMOJIS,
        };
      },
      update(data) {
        const widgets = data.workspace?.workItem?.widgets;
        return widgets?.find((widget) => widget.type === WIDGET_TYPE_AWARD_EMOJI).awardEmoji || {};
      },
      skip() {
        return !this.workItemIid;
      },
      result({ data }) {
        if (this.hasNextPage) {
          this.fetchAwardEmojis();
        } else {
          this.isLoading = false;
        }
        if (data) {
          this.$emit('emoji-updated', data.workspace?.workItem);
        }
      },
      error() {
        this.$emit('error', I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR);
      },
    },
  },
  methods: {
    async fetchAwardEmojis() {
      this.isLoading = true;
      try {
        await this.$apollo.queries.awardEmoji.fetchMore({
          variables: {
            pageSize: DEFAULT_PAGE_SIZE_EMOJIS,
            after: this.pageInfo?.endCursor,
          },
        });
      } catch {
        this.$emit('error', I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR);
      }
    },
    isEmojiPresentForCurrentUser(name) {
      return (
        this.awards.findIndex(
          (emoji) => emoji.name === name && emoji.user.id === this.currentUserId,
        ) > -1
      );
    },
    /**
     * Prepare emoji reactions nodes based on emoji name
     * and whether the user has toggled the emoji off or on
     */
    getAwardEmojiNodes(name, toggledOn) {
      // If the emoji toggled on, add the emoji
      if (toggledOn) {
        // If emoji is already present in award list, no action is needed
        if (this.isEmojiPresentForCurrentUser(name)) {
          return this.awardEmoji.nodes;
        }

        // else make a copy of immutable list and return the list after adding the new emoji
        const awardEmojiNodes = [...this.awardEmoji.nodes];
        awardEmojiNodes.push({
          name,
          __typename: 'AwardEmoji',
          user: {
            id: convertToGraphQLId(TYPENAME_USER, this.currentUserId),
            name: this.currentUserFullName,
            __typename: 'UserCore',
          },
        });

        return awardEmojiNodes;
      }

      // else just filter the emoji
      return this.awardEmoji.nodes.filter(
        (emoji) =>
          !(emoji.name === name && getIdFromGraphQLId(emoji.user.id) === this.currentUserId),
      );
    },
    updateWorkItemAwardEmojiWidgetCache({ cache, name, toggledOn }) {
      const query = {
        query: projectWorkItemAwardEmojiQuery,
        variables: {
          fullPath: this.workItemFullpath,
          iid: this.workItemIid,
          pageSize: DEFAULT_PAGE_SIZE_EMOJIS,
        },
      };

      const sourceData = cache.readQuery(query);

      const newData = produce(sourceData, (draftState) => {
        const { widgets } = draftState.workspace.workItem;
        const widgetAwardEmoji = widgets.find((widget) => widget.type === WIDGET_TYPE_AWARD_EMOJI);
        widgetAwardEmoji.awardEmoji.nodes = this.getAwardEmojiNodes(name, toggledOn);
      });

      cache.writeQuery({ ...query, data: newData });
    },
    handleAward(name) {
      // Decide action based on emoji is already present
      const inputVariables = {
        awardableId: this.workItemId,
        name,
      };

      this.$apollo
        .mutate({
          mutation: updateAwardEmojiMutation,
          variables: {
            input: inputVariables,
          },
          optimisticResponse: {
            awardEmojiToggle: {
              errors: [],
              toggledOn: !this.isEmojiPresentForCurrentUser(name),
            },
          },
          update: (
            cache,
            {
              data: {
                awardEmojiToggle: { toggledOn },
              },
            },
          ) => {
            // update the cache of emoji reactions widget object
            this.updateWorkItemAwardEmojiWidgetCache({ cache, name, toggledOn });
          },
        })
        .then(
          ({
            data: {
              awardEmojiToggle: { errors },
            },
          }) => {
            if (errors?.length) {
              throw new Error(errors[0]);
            }
          },
        )
        .catch((error) => {
          this.$emit('error', error.message);
          Sentry.captureException(error);
        });
    },
  },
};
</script>

<template>
  <div v-if="!isLoading">
    <awards-list
      :awards="awards"
      :can-award-emoji="$options.isLoggedIn"
      :current-user-id="currentUserId"
      :default-awards="$options.defaultAwards"
      selected-class="selected"
      @award="handleAward"
    />
  </div>
</template>
