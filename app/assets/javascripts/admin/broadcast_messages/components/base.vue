<script>
import { GlButton, GlCard, GlIcon, GlPagination } from '@gitlab/ui';
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
    GlButton,
    GlCard,
    GlIcon,
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
    title: s__('BroadcastMessages|Messages'),
    addTitle: s__('BroadcastMessages|Add new message'),
    emptyMessage: s__('BroadcastMessages|No broadcast messages defined yet.'),
    addButton: s__('BroadcastMessages|Add new message'),
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
      showAddForm: false,
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
    toggleAddForm() {
      this.showAddForm = !this.showAddForm;
    },
    closeAddForm() {
      this.showAddForm = false;
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
    <gl-card
      class="gl-new-card"
      header-class="gl-new-card-header"
      body-class="gl-new-card-body gl-overflow-hidden gl-px-0"
    >
      <template #header>
        <div class="gl-new-card-title-wrapper">
          <h3 class="gl-new-card-title">{{ $options.i18n.title }}</h3>
          <div class="gl-new-card-count">
            <gl-icon name="messages" class="gl-mr-2" />
            {{ messagesCount }}
          </div>
        </div>
        <gl-button v-if="!showAddForm" size="small" @click="toggleAddForm">{{
          $options.i18n.addButton
        }}</gl-button>
      </template>

      <div v-if="showAddForm" class="gl-new-card-add-form gl-m-3">
        <h4 class="gl-mt-0">{{ $options.i18n.addTitle }}</h4>
        <message-form
          :broadcast-message="$options.NEW_BROADCAST_MESSAGE"
          @close-add-form="closeAddForm"
        />
      </div>

      <messages-table
        v-if="hasVisibleMessages"
        :messages="visibleMessages"
        @delete-message="deleteMessage"
      />
      <div v-else-if="!showAddForm" class="gl-new-card-empty gl-px-5 gl-py-4">
        {{ $options.i18n.emptyMessage }}
      </div>
    </gl-card>

    <gl-pagination
      v-model="currentPage"
      :total-items="totalMessages"
      :link-gen="buildPageUrl"
      align="center"
      class="gl-mt-5"
    />
  </div>
</template>
