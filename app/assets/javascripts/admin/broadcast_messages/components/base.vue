<script>
import { GlPagination } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import { buildUrlWithCurrentLocation } from '~/lib/utils/common_utils';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { NEW_BROADCAST_MESSAGE } from '../constants';
import MessageForm from './message_form.vue';
import MessagesTable from './messages_table.vue';

const PER_PAGE = 20;

export default {
  name: 'BroadcastMessagesBase',
  NEW_BROADCAST_MESSAGE,
  components: {
    GlPagination,
    CrudComponent,
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
        visitUrl(this.buildPageUrl(1));
      }
    },
  },

  methods: {
    buildPageUrl(newPage) {
      return buildUrlWithCurrentLocation(`?page=${newPage}`);
    },
    closeAddForm() {
      this.showAddForm = false;
      this.$refs.crudComponent.hideForm();
    },
    setVisibleMessages({ index, message, value }) {
      const copy = [...this.visibleMessages];
      copy[index] = { ...message, disable_delete: value };
      this.visibleMessages = copy;
    },
    async deleteMessage(messageId) {
      const index = this.visibleMessages.findIndex((m) => m.id === messageId);
      if (!index === -1) return;

      const message = this.visibleMessages[index];
      this.setVisibleMessages({ index, message, value: true });

      try {
        await axios.delete(message.delete_path);
      } catch (e) {
        this.setVisibleMessages({ index, message, value: false });
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
    <crud-component
      ref="crudComponent"
      :title="$options.i18n.title"
      icon="bullhorn"
      :count="messagesCount"
      :toggle-text="$options.i18n.addButton"
    >
      <template #form>
        <h4 class="gl-mt-0">{{ $options.i18n.addTitle }}</h4>
        <message-form
          :broadcast-message="$options.NEW_BROADCAST_MESSAGE"
          @close-add-form="closeAddForm"
        />
      </template>

      <messages-table
        v-if="hasVisibleMessages"
        :messages="visibleMessages"
        @delete-message="deleteMessage"
      />
      <div v-else-if="!showAddForm" class="gl-text-subtle">
        {{ $options.i18n.emptyMessage }}
      </div>

      <template #pagination>
        <gl-pagination
          v-model="currentPage"
          :total-items="totalMessages"
          :link-gen="buildPageUrl"
          align="center"
        />
      </template>
    </crud-component>
  </div>
</template>
