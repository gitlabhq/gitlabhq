<script>
import { GlButton, GlLink, GlDropdownItem, GlDisclosureDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import {
  TRIGGER_ELEMENT_BUTTON,
  TRIGGER_ELEMENT_WITH_EMOJI,
  TRIGGER_ELEMENT_DROPDOWN_WITH_EMOJI,
  TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN,
} from '../constants';

export default {
  components: { GlButton, GlLink, GlDropdownItem, GlDisclosureDropdownItem },
  props: {
    displayText: {
      type: String,
      required: false,
      default: s__('InviteMembers|Invite team members'),
    },
    icon: {
      type: String,
      required: false,
      default: '',
    },
    classes: {
      type: String,
      required: false,
      default: '',
    },
    variant: {
      type: String,
      required: false,
      default: undefined,
    },
    category: {
      type: String,
      required: false,
      default: undefined,
    },
    triggerSource: {
      type: String,
      required: true,
    },
    triggerElement: {
      type: String,
      required: false,
      default: 'button',
    },
  },
  computed: {
    componentAttributes() {
      return {
        class: this.classes,
        'data-testid': 'invite-members-button',
      };
    },
    item() {
      return { text: this.displayText };
    },
    isButtonTrigger() {
      return this.triggerElement === TRIGGER_ELEMENT_BUTTON;
    },
    isWithEmojiTrigger() {
      return this.triggerElement === TRIGGER_ELEMENT_WITH_EMOJI;
    },
    isDropdownWithEmojiTrigger() {
      return this.triggerElement === TRIGGER_ELEMENT_DROPDOWN_WITH_EMOJI;
    },
    isDisclosureTrigger() {
      return this.triggerElement === TRIGGER_ELEMENT_DISCLOSURE_DROPDOWN;
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', { source: this.triggerSource });
    },
    handleDisclosureDropdownAction() {
      this.openModal();
      this.$emit('modal-opened');
    },
  },
};
</script>

<template>
  <gl-button
    v-if="isButtonTrigger"
    v-bind="componentAttributes"
    :variant="variant"
    :category="category"
    :icon="icon"
    @click="openModal"
  >
    {{ displayText }}
  </gl-button>
  <gl-link v-else-if="isWithEmojiTrigger" v-bind="componentAttributes" @click="openModal">
    {{ displayText }}
    <gl-emoji class="gl-mr-1 gl-align-baseline gl-text-size-reset" :data-name="icon" />
  </gl-link>
  <gl-dropdown-item
    v-else-if="isDropdownWithEmojiTrigger"
    v-bind="componentAttributes"
    @click="openModal"
  >
    {{ displayText }}
    <gl-emoji class="gl-mr-1 gl-align-baseline gl-text-size-reset" :data-name="icon" />
  </gl-dropdown-item>
  <gl-disclosure-dropdown-item
    v-else-if="isDisclosureTrigger"
    v-bind="componentAttributes"
    :item="item"
    @action="handleDisclosureDropdownAction"
  />
  <gl-link v-else v-bind="componentAttributes" data-is-link="true" @click="openModal">
    {{ displayText }}
  </gl-link>
</template>
