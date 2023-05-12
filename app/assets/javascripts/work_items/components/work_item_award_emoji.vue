<script>
import * as Sentry from '@sentry/browser';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import {
  EMOJI_ACTION_REMOVE,
  EMOJI_ACTION_ADD,
  WIDGET_TYPE_AWARD_EMOJI,
  EMOJI_THUMBSDOWN,
  EMOJI_THUMBSUP,
} from '../constants';

export default {
  defaultAwards: [EMOJI_THUMBSUP, EMOJI_THUMBSDOWN],
  isLoggedIn: isLoggedIn(),
  components: {
    AwardsList,
  },
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    awardEmoji: {
      type: Object,
      required: true,
    },
  },
  computed: {
    currentUserId() {
      return window.gon.current_user_id;
    },
    /**
     * Parse and convert award emoji list to a format that AwardsList can understand
     */
    awards() {
      return this.awardEmoji.nodes.map((emoji, index) => ({
        id: index + 1,
        name: emoji.name,
        user: {
          id: getIdFromGraphQLId(emoji.user.id),
        },
      }));
    },
  },
  methods: {
    handleAward(name) {
      // Decide action based on emoji is already present
      const action =
        this.awards.findIndex((emoji) => emoji.name === name) > -1
          ? EMOJI_ACTION_REMOVE
          : EMOJI_ACTION_ADD;
      const inputVariables = {
        id: this.workItem.id,
        awardEmojiWidget: {
          action,
          name,
        },
      };

      this.$apollo
        .mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: inputVariables,
          },
          optimisticResponse: this.getOptimisticResponse({ name, action }),
        })
        .then(
          ({
            data: {
              workItemUpdate: { errors },
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
    /**
     * Prepare workItemUpdate for optimistic response
     */
    getOptimisticResponse({ name, action }) {
      let awardEmojiNodes = [
        ...this.awardEmoji.nodes,
        {
          name,
          __typename: 'AwardEmoji',
          user: {
            id: convertToGraphQLId(TYPENAME_USER, this.currentUserId),
            __typename: 'UserCore',
          },
        },
      ];
      // Exclude the award emoji node in case of remove action
      if (action === EMOJI_ACTION_REMOVE) {
        awardEmojiNodes = [...this.awardEmoji.nodes.filter((emoji) => emoji.name !== name)];
      }
      return {
        workItemUpdate: {
          errors: [],
          workItem: {
            ...this.workItem,
            widgets: [
              {
                type: WIDGET_TYPE_AWARD_EMOJI,
                awardEmoji: {
                  nodes: awardEmojiNodes,
                  __typename: 'AwardEmojiConnection',
                },
                __typename: 'WorkItemWidgetAwardEmoji',
              },
            ],
            __typename: 'WorkItem',
          },
          __typename: 'WorkItemUpdatePayload',
        },
      };
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
