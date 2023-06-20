<script>
import * as Sentry from '@sentry/browser';
import { produce } from 'immer';

import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';

import updateAwardEmojiMutation from '../graphql/update_award_emoji.mutation.graphql';
import workItemByIidQuery from '../graphql/work_item_by_iid.query.graphql';
import { EMOJI_THUMBSDOWN, EMOJI_THUMBSUP, WIDGET_TYPE_AWARD_EMOJI } from '../constants';

export default {
  defaultAwards: [EMOJI_THUMBSUP, EMOJI_THUMBSDOWN],
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
    awardEmoji: {
      type: Object,
      required: true,
    },
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    currentUserId() {
      return window.gon.current_user_id;
    },
    currentUserFullName() {
      return window.gon.current_user_fullname;
    },
    /**
     * Parse and convert award emoji list to a format that AwardsList can understand
     */
    awards() {
      return this.awardEmoji.nodes.map((emoji) => ({
        name: emoji.name,
        user: {
          id: getIdFromGraphQLId(emoji.user.id),
          name: emoji.user.name,
        },
      }));
    },
  },
  methods: {
    getAwards() {
      return this.awardEmoji.nodes.map((emoji) => ({
        name: emoji.name,
        user: {
          id: getIdFromGraphQLId(emoji.user.id),
          name: emoji.user.name,
        },
      }));
    },
    isEmojiPresentForCurrentUser(name) {
      return (
        this.awards.findIndex(
          (emoji) => emoji.name === name && emoji.user.id === this.currentUserId,
        ) > -1
      );
    },
    /**
     * Prepare award emoji nodes based on emoji name
     * and whether the user has toggled the emoji off or on
     */
    getAwardEmojiNodes(name, toggledOn) {
      // If the emoji toggled on, add the emoji
      if (toggledOn) {
        // If emoji is already present in award list, no action is needed
        if (this.isEmojiPresentForCurrentUser(name)) {
          return this.awardEmoji.nodes;
        }

        // else make a copy of unmutable list and return the list after adding the new emoji
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
        query: workItemByIidQuery,
        variables: { fullPath: this.workItemFullpath, iid: this.workItemIid },
      };

      const sourceData = cache.readQuery(query);

      const newData = produce(sourceData, (draftState) => {
        const { widgets } = draftState.workspace.workItems.nodes[0];
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
            // update the cache of award emoji widget object
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
  <div class="gl-mt-3">
    <awards-list
      data-testid="work-item-award-list"
      :awards="awards"
      :can-award-emoji="$options.isLoggedIn"
      :current-user-id="currentUserId"
      :default-awards="$options.defaultAwards"
      selected-class="selected"
      @award="handleAward"
    />
  </div>
</template>
