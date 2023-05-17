<script>
import { GlPagination } from '@gitlab/ui';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import { NEW_BROADCAST_MESSAGE } from '../constants';
import MessageForm from './message_form.vue';
import MessagesTable from './messages_table.vue';

const PER_PAGE = 20;

export default {
  name: 'BroadcastMessagesBase',
  NEW_BROADCAST_MESSAGE,
  components: {
    GlPagination,
    MessageForm,
    MessagesTable,
  },

  props: {
    page: {
      type: Number,
      required: true,
    },
    messagesCount: {
      type: Number,
      required: true,
    },
    messages: {
      type: Array,
      required: true,
    },
  },

  i18n: {
    deleteError: s__(
      'BroadcastMessages|There was an issue deleting this message, please try again later.',
    ),
  },

  data() {
    return {
      currentPage: this.page,
      totalMessages: this.messagesCount,
      visibleMessages: this.messages.map((message) => ({
        ...message,
        disable_delete: false,
      })),
    };
  },

  computed: {
    hasVisibleMessages() {
      return this.visibleMessages.length > 0;
    },
  },

  watch: {
    totalMessages(newVal, oldVal) {
      // Pagination controls disappear when there is only
      // one page worth of messages. Since we're relying on static data,
      // this could hide messages on the next page, or leave the user
      // stranded on page 2 when deleting the last message.
      // Force a page reload to avoid this edge case.
      if (newVal === PER_PAGE && oldVal === PER_PAGE + 1) {
        redirectTo(this.buildPageUrl(1)); // eslint-disable-line import/no-deprecated
      }
    },
  },

  methods: {
    buildPageUrl(newPage) {
      return buildUrlWithCurrentLocation(`?page=${newPage}`);
    },

    async deleteMessage(messageId) {
      const index = this.visibleMessages.findIndex((m) => m.id === messageId);
      if (!index === -1) return;

      const message = this.visibleMessages[index];
      this.$set(this.visibleMessages, index, { ...message, disable_delete: true });

      try {
        await axios.delete(message.delete_path);
      } catch (e) {
        this.$set(this.visibleMessages, index, { ...message, disable_delete: false });
        createAlert({ message: this.$options.i18n.deleteError, variant: VARIANT_DANGER });
        return;
      }

      // Remove the message from the table
      this.visibleMessages = this.visibleMessages.filter((m) => m.id !== messageId);
      this.totalMessages -= 1;
    },
  },
};
</script>

<template>
  <div>
    <message-form :broadcast-message="$options.NEW_BROADCAST_MESSAGE" />
    <messages-table
      v-if="hasVisibleMessages"
      :messages="visibleMessages"
      @delete-message="deleteMessage"
    />
    <gl-pagination
      v-model="currentPage"
      :total-items="totalMessages"
      :link-gen="buildPageUrl"
      align="center"
    />
  </div>
</template>
