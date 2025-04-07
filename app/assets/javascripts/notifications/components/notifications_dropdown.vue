<script>
import { GlCollapsibleListbox, GlTooltipDirective, GlButtonGroup, GlButton } from '@gitlab/ui';
import Api from '~/api';
import { sprintf } from '~/locale';
import { CUSTOM_LEVEL, i18n } from '../constants';
import CustomNotificationsModal from './custom_notifications_modal.vue';

export default {
  name: 'NotificationsDropdown',
  components: {
    GlCollapsibleListbox,
    GlButtonGroup,
    GlButton,
    CustomNotificationsModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: {
    containerClass: {
      default: '',
    },
    emailsDisabled: {
      default: false,
    },
    dropdownItems: {
      default: [],
    },
    buttonSize: {
      default: 'medium',
    },
    initialNotificationLevel: {
      default: '',
    },
    projectId: {
      default: null,
    },
    groupId: {
      default: null,
    },
    showLabel: {
      default: false,
    },
  },
  data() {
    return {
      selectedNotificationLevel: this.initialNotificationLevel,
      isLoading: false,
      notificationsModalVisible: false,
    };
  },
  computed: {
    notificationLevels() {
      const levels = this.dropdownItems.map((level) => ({
        value: level,
        text: this.$options.i18n.notificationTitles[level] || '',
        secondaryText: this.$options.i18n.notificationDescriptions[level] || '',
      }));
      return [
        {
          text: '',
          options: levels,
        },
        {
          text: this.$options.i18n.notificationTitles.custom,
          textSrOnly: true,
          options: [
            {
              value: this.$options.customLevel,
              text: this.$options.i18n.notificationTitles.custom,
              secondaryText: this.$options.i18n.notificationDescriptions.custom,
            },
          ],
        },
      ];
    },
    isCustomNotification() {
      return this.selectedNotificationLevel === CUSTOM_LEVEL;
    },
    buttonIcon() {
      if (this.isLoading) {
        return '';
      }

      return this.selectedNotificationLevel === 'disabled' ? 'notifications-off' : 'notifications';
    },
    buttonText() {
      const notificationTitle =
        this.$options.i18n.notificationTitles[this.selectedNotificationLevel] ||
        this.selectedNotificationLevel;

      if (this.showLabel) {
        return notificationTitle;
      }

      return this.emailsDisabled
        ? this.$options.i18n.notificationDescriptions.owner_disabled
        : sprintf(this.$options.i18n.notificationTooltipTitle, {
            notification_title: notificationTitle,
          });
    },
    ariaLabel() {
      return sprintf(this.$options.i18n.notificationTooltipTitle, {
        notification_title: this.$options.i18n.notificationTitles[this.selectedNotificationLevel],
      });
    },
  },
  methods: {
    openNotificationsModal() {
      if (this.isCustomNotification) {
        this.notificationsModalVisible = true;
      }
    },
    selectItem(level) {
      if (level !== this.selectedNotificationLevel) {
        this.updateNotificationLevel(level);
      }
    },
    async updateNotificationLevel(level) {
      this.isLoading = true;

      try {
        await Api.updateNotificationSettings(this.projectId, this.groupId, { level });
        this.selectedNotificationLevel = level;
        this.openNotificationsModal();
      } catch (error) {
        this.$toast.show(this.$options.i18n.updateNotificationLevelErrorMessage);
      } finally {
        this.isLoading = false;
      }
    },
  },
  customLevel: CUSTOM_LEVEL,
  i18n,
  modalId: 'custom-notifications-modal',
};
</script>

<template>
  <div :class="containerClass">
    <gl-button-group>
      <gl-button
        v-if="isCustomNotification"
        v-gl-tooltip="{ title: buttonText }"
        data-testid="notification-split-icon"
        category="primary"
        variant="default"
        :aria-label="__('Notification setting - Custom')"
        :size="buttonSize"
        :icon="buttonIcon"
        @click="openNotificationsModal"
      />
      <gl-collapsible-listbox
        v-gl-tooltip="{ title: buttonText }"
        data-testid="notification-dropdown"
        :size="buttonSize"
        :icon="isCustomNotification ? '' : buttonIcon"
        :items="notificationLevels"
        :toggle-text="buttonText"
        :loading="isLoading"
        :disabled="emailsDisabled"
        :aria-label="ariaLabel"
        :selected="selectedNotificationLevel"
        :text-sr-only="!showLabel || isCustomNotification"
        @select="selectItem"
      >
        <template #list-item="{ item }">
          <div class="gl-flex gl-flex-col">
            <span class="gl-font-bold">{{ item.text }}</span>
            <span class="gl-text-sm gl-text-subtle">{{ item.secondaryText }}</span>
          </div>
        </template>
      </gl-collapsible-listbox>
    </gl-button-group>
    <custom-notifications-modal v-model="notificationsModalVisible" :modal-id="$options.modalId" />
  </div>
</template>
