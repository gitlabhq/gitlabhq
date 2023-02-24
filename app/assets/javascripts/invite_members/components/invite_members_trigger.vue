<script>
import { GlButton, GlLink, GlIcon, GlDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';
import {
  TRIGGER_ELEMENT_BUTTON,
  TRIGGER_ELEMENT_SIDE_NAV,
  TRIGGER_DEFAULT_QA_SELECTOR,
  TRIGGER_ELEMENT_WITH_EMOJI,
  TRIGGER_ELEMENT_DROPDOWN_WITH_EMOJI,
} from '../constants';

export default {
  components: { GlButton, GlLink, GlIcon, GlDropdownItem },
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
    triggerSource: {
      type: String,
      required: true,
    },
    triggerElement: {
      type: String,
      required: false,
      default: 'button',
    },
    event: {
      type: String,
      required: false,
      default: '',
    },
    label: {
      type: String,
      required: false,
      default: '',
    },
    qaSelector: {
      type: String,
      required: false,
      default: TRIGGER_DEFAULT_QA_SELECTOR,
    },
  },
  computed: {
    componentAttributes() {
      const baseAttributes = {
        class: this.classes,
        'data-qa-selector': this.qaSelector,
        'data-test-id': 'invite-members-button',
      };

      if (this.event && this.label) {
        return {
          ...baseAttributes,
          'data-track-action': this.event,
          'data-track-label': this.label,
        };
      }

      return baseAttributes;
    },
  },
  methods: {
    checkTrigger(targetTriggerElement) {
      return this.triggerElement === targetTriggerElement;
    },
    openModal() {
      eventHub.$emit('openModal', { source: this.triggerSource });
    },
  },
  TRIGGER_ELEMENT_BUTTON,
  TRIGGER_ELEMENT_SIDE_NAV,
  TRIGGER_ELEMENT_WITH_EMOJI,
  TRIGGER_ELEMENT_DROPDOWN_WITH_EMOJI,
};
</script>

<template>
  <gl-button
    v-if="checkTrigger($options.TRIGGER_ELEMENT_BUTTON)"
    v-bind="componentAttributes"
    :variant="variant"
    :icon="icon"
    @click="openModal"
  >
    {{ displayText }}
  </gl-button>
  <gl-link
    v-else-if="checkTrigger($options.TRIGGER_ELEMENT_SIDE_NAV)"
    v-bind="componentAttributes"
    data-is-link="true"
    @click="openModal"
  >
    <span class="nav-icon-container">
      <gl-icon :name="icon" />
    </span>
    <span class="nav-item-name"> {{ displayText }} </span>
  </gl-link>
  <gl-link
    v-else-if="checkTrigger($options.TRIGGER_ELEMENT_WITH_EMOJI)"
    v-bind="componentAttributes"
    @click="openModal"
  >
    {{ displayText }}
    <gl-emoji class="gl-vertical-align-baseline gl-reset-font-size gl-mr-1" :data-name="icon" />
  </gl-link>
  <gl-dropdown-item
    v-else-if="checkTrigger($options.TRIGGER_ELEMENT_DROPDOWN_WITH_EMOJI)"
    v-bind="componentAttributes"
    button-class="top-nav-menu-item"
    @click="openModal"
  >
    {{ displayText }}
    <gl-emoji class="gl-vertical-align-baseline gl-reset-font-size gl-mr-1" :data-name="icon" />
  </gl-dropdown-item>
  <gl-link v-else v-bind="componentAttributes" data-is-link="true" @click="openModal">
    {{ displayText }}
  </gl-link>
</template>
