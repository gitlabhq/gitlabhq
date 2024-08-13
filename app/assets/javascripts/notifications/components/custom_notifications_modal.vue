<script>
import { GlModal, GlSprintf, GlLink, GlLoadingIcon, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import { sortBy } from 'lodash';
import Api from '~/api';
import { i18n } from '../constants';

export default {
  name: 'CustomNotificationsModal',
  components: {
    GlModal,
    GlSprintf,
    GlLink,
    GlLoadingIcon,
    GlFormGroup,
    GlFormCheckbox,
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
    open() {
      this.$refs.modal.show();
    },
    buildEvents(events) {
      const rawEvents = Object.keys(events).map((key) => ({
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
    :title="$options.i18n.customNotificationsModal.title"
    @show="onOpen"
    v-on="$listeners"
  >
    <div class="container-fluid">
      <div class="row">
        <div class="col-lg-4">
          <h4 class="gl-mt-0" data-testid="modalBodyTitle">
            {{ $options.i18n.customNotificationsModal.bodyTitle }}
          </h4>
          <gl-sprintf :message="$options.i18n.customNotificationsModal.bodyMessage">
            <template #notificationLink="{ content }">
              <gl-link :href="helpPagePath" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </div>
        <div class="col-lg-8">
          <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3" />
          <template v-else>
            <gl-form-group v-for="event in events" :key="event.id">
              <gl-form-checkbox
                v-model="event.enabled"
                :data-testid="`notification-setting-${event.id}`"
                @change="updateEvent($event, event)"
              >
                <strong>{{ event.name }}</strong
                ><gl-loading-icon v-if="event.loading" size="sm" :inline="true" class="gl-ml-2" />
              </gl-form-checkbox>
            </gl-form-group>
          </template>
        </div>
      </div>
    </div>
  </gl-modal>
</template>
