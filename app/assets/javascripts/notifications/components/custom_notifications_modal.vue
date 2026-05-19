<script>
import { GlCard, GlModal, GlSprintf, GlLink, GlLoadingIcon, GlToggle } from '@gitlab/ui';
import { sortBy } from 'lodash-es';
import Api from '~/api';
import { i18n } from '../constants';

export default {
  name: 'CustomNotificationsModal',
  components: {
    GlCard,
    GlModal,
    GlSprintf,
    GlLink,
    GlLoadingIcon,
    GlToggle,
  },
  inject: {
    projectId: {
      default: null,
    },
    groupId: {
      default: null,
    },
    helpPagePath: {
      default: '',
    },
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    modalId: {
      type: String,
      required: false,
      default: 'custom-notifications-modal',
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isLoading: false,
      events: [],
    };
  },
  methods: {
    buildEvents(events) {
      const eventKeys = Object.keys(events).filter((key) => key in this.$options.i18n.eventNames);
      const rawEvents = eventKeys.map((key) => ({
        id: key,
        enabled: Boolean(events[key]),
        name: this.$options.i18n.eventNames[key] || '',
        loading: false,
      }));

      return sortBy(rawEvents, 'name');
    },
    async onOpen() {
      if (!this.events.length) {
        await this.loadNotificationSettings();
      }
    },
    async loadNotificationSettings() {
      this.isLoading = true;

      try {
        const {
          data: { events },
        } = await Api.getNotificationSettings(this.projectId, this.groupId);

        this.events = this.buildEvents(events);
      } catch (error) {
        this.$toast.show(this.$options.i18n.loadNotificationLevelErrorMessage);
      } finally {
        this.isLoading = false;
      }
    },
    async updateEvent(isEnabled, event) {
      const index = this.events.findIndex((e) => e.id === event.id);

      // update loading state for the given event
      this.events.splice(index, 1, { ...this.events[index], loading: true });

      try {
        const {
          data: { events },
        } = await Api.updateNotificationSettings(this.projectId, this.groupId, {
          [event.id]: isEnabled,
        });

        this.events = this.buildEvents(events);
      } catch (error) {
        this.$toast.show(this.$options.i18n.updateNotificationLevelErrorMessage);
      }
    },
  },
  i18n,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :visible="visible"
    :modal-id="modalId"
    scrollable
    hide-footer
    :title="$options.i18n.customNotificationsModal.title"
    @show="onOpen"
    v-on="$listeners"
  >
    <gl-sprintf :message="$options.i18n.customNotificationsModal.bodyMessage">
      <template #notificationLink="{ content }">
        <gl-link :href="helpPagePath" target="_blank">{{ content }}</gl-link>
      </template>
    </gl-sprintf>
    <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3" />
    <template v-else>
      <gl-card class="gl-mt-5" body-class="gl-py-0">
        <template #header>
          <h3>{{ __('Notification events') }}</h3>
        </template>
        <ul class="gl-m-0 gl-flex gl-flex-col gl-p-0">
          <li
            v-for="event in events"
            :key="event.id"
            class="gl-border-b gl-flex gl-items-center gl-justify-between gl-p-4 last:gl-border-none"
            @click="updateEvent(!event.enabled, event)"
          >
            <span class="gl-font-bold">{{ event.name }}</span>
            <span @click.stop>
              <gl-toggle
                :value="event.enabled"
                :label="event.name"
                label-position="hidden"
                :is-loading="event.loading"
                :data-testid="`notification-setting-${event.id}`"
                @change="updateEvent($event, event)"
              />
            </span>
          </li>
        </ul>
      </gl-card>
    </template>
  </gl-modal>
</template>
