<script>
import {
  GlFormGroup,
  GlFormSelect,
  GlModal,
  GlDatepicker,
  GlLink,
  GlSprintf,
  GlButton,
} from '@gitlab/ui';

import Tracking from '~/tracking';
import { sprintf } from '~/locale';
import ContentTransition from '~/vue_shared/components/content_transition.vue';
import {
  ACCESS_LEVEL,
  ACCESS_EXPIRE_DATE,
  READ_MORE_TEXT,
  INVITE_BUTTON_TEXT,
  INVITE_BUTTON_TEXT_DISABLED,
  CANCEL_BUTTON_TEXT,
  HEADER_CLOSE_LABEL,
  ON_SHOW_TRACK_LABEL,
} from '../constants';

const DEFAULT_SLOT = 'default';
const DEFAULT_SLOTS = [
  {
    key: DEFAULT_SLOT,
    attributes: {
      class: 'invite-modal-content',
      'data-testid': 'invite-modal-initial-content',
    },
  },
];

export default {
  components: {
    GlFormGroup,
    GlFormSelect,
    GlDatepicker,
    GlLink,
    GlModal,
    GlSprintf,
    GlButton,
    ContentTransition,
  },
  mixins: [Tracking.mixin()],
  inheritAttrs: false,
  props: {
    modalTitle: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    accessLevels: {
      type: Object,
      required: true,
    },
    defaultAccessLevel: {
      type: Number,
      required: true,
    },
    helpLink: {
      type: String,
      required: true,
    },
    labelIntroText: {
      type: String,
      required: true,
    },
    labelSearchField: {
      type: String,
      required: true,
    },
    formGroupDescription: {
      type: String,
      required: false,
      default: '',
    },
    submitDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    invalidFeedbackMessage: {
      type: String,
      required: false,
      default: '',
    },
    submitButtonText: {
      type: String,
      required: false,
      default: INVITE_BUTTON_TEXT,
    },
    cancelButtonText: {
      type: String,
      required: false,
      default: CANCEL_BUTTON_TEXT,
    },
    currentSlot: {
      type: String,
      required: false,
      default: DEFAULT_SLOT,
    },
    extraSlots: {
      type: Array,
      required: false,
      default: () => [],
    },
    preventCancelDefault: {
      type: Boolean,
      required: false,
      default: false,
    },
    usersLimitDataset: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    // Be sure to check out reset!
    return {
      selectedAccessLevel: this.defaultAccessLevel,
      selectedDate: undefined,
      minDate: new Date(),
    };
  },
  computed: {
    accessLevelsOptions() {
      return Object.entries(this.accessLevels).map(([text, value]) => ({ text, value }));
    },
    introText() {
      return sprintf(this.labelIntroText, { name: this.name });
    },
    exceptionState() {
      return this.invalidFeedbackMessage ? false : null;
    },
    selectId() {
      return `${this.modalId}_search`;
    },
    dropdownId() {
      return `${this.modalId}_dropdown`;
    },
    datepickerId() {
      return `${this.modalId}_expires_at`;
    },
    selectedRoleName() {
      return Object.keys(this.accessLevels).find(
        (key) => this.accessLevels[key] === Number(this.selectedAccessLevel),
      );
    },
    contentSlots() {
      return [...DEFAULT_SLOTS, ...(this.extraSlots || [])];
    },
    actionPrimary() {
      return {
        text: this.submitButtonText,
        attributes: {
          variant: 'confirm',
          disabled: this.submitDisabled,
          loading: this.isLoading,
          'data-qa-selector': 'invite_button',
        },
      };
    },
    actionCancel() {
      if (this.usersLimitDataset.closeToDashboardLimit && this.usersLimitDataset.userNamespace) {
        return {
          text: INVITE_BUTTON_TEXT_DISABLED,
          attributes: {
            href: this.usersLimitDataset.membersPath,
            category: 'secondary',
            variant: 'confirm',
          },
        };
      }

      return {
        text: this.cancelButtonText,
      };
    },
  },
  watch: {
    selectedAccessLevel: {
      immediate: true,
      handler(val) {
        this.$emit('access-level', val);
      },
    },
  },
  methods: {
    onReset() {
      // This component isn't necessarily disposed,
      // so we might need to reset it's state.
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;

      this.$emit('reset');
    },
    onShowModal() {
      if (this.usersLimitDataset.reachedLimit) {
        this.track('render', { category: 'default', label: ON_SHOW_TRACK_LABEL });
      }
    },
    onCancel(e) {
      if (this.preventCancelDefault) {
        e.preventDefault();
      } else {
        this.onReset();
        this.$refs.modal.hide();
      }

      this.$emit('cancel');
    },
    onSubmit(e) {
      // We never want to hide when submitting
      e.preventDefault();

      this.$emit('submit', {
        accessLevel: this.selectedAccessLevel,
        expiresAt: this.selectedDate,
      });
    },
    onClose() {
      this.$emit('close');
    },
  },
  HEADER_CLOSE_LABEL,
  ACCESS_EXPIRE_DATE,
  ACCESS_LEVEL,
  READ_MORE_TEXT,
  INVITE_BUTTON_TEXT,
  CANCEL_BUTTON_TEXT,
  DEFAULT_SLOT,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    data-qa-selector="invite_members_modal_content"
    data-testid="invite-modal"
    size="sm"
    dialog-class="gl-mx-5"
    :title="modalTitle"
    :header-close-label="$options.HEADER_CLOSE_LABEL"
    no-focus-on-show
    @shown="onShowModal"
    @close="onClose"
    @hidden="onReset"
  >
    <content-transition
      class="gl-display-grid"
      transition-name="invite-modal-transition"
      :slots="contentSlots"
      :current-slot="currentSlot"
    >
      <template #[$options.DEFAULT_SLOT]>
        <div class="gl-display-flex" data-testid="modal-base-intro-text">
          <slot name="intro-text-before"></slot>
          <p>
            <gl-sprintf :message="introText">
              <template #strong="{ content }">
                <strong>{{ content }}</strong>
              </template>
            </gl-sprintf>
            <slot name="intro-text-after"></slot>
          </p>
        </div>

        <slot name="alert"></slot>
        <slot name="active-trial-alert"></slot>

        <gl-form-group
          :label="labelSearchField"
          :label-for="selectId"
          :invalid-feedback="invalidFeedbackMessage"
          :state="exceptionState"
          :description="formGroupDescription"
          data-testid="members-form-group"
        >
          <slot name="select" v-bind="{ exceptionState, inputId: selectId }"></slot>
        </gl-form-group>

        <gl-form-group
          class="gl-w-half gl-xs-w-full"
          :label="$options.ACCESS_LEVEL"
          :label-for="dropdownId"
        >
          <template #description>
            <gl-sprintf :message="$options.READ_MORE_TEXT">
              <template #link="{ content }">
                <gl-link :href="helpLink" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </template>
          <gl-form-select
            :id="dropdownId"
            v-model="selectedAccessLevel"
            data-qa-selector="access_level_dropdown"
            :options="accessLevelsOptions"
          />
        </gl-form-group>

        <gl-form-group
          class="gl-w-half gl-xs-w-full"
          :label="$options.ACCESS_EXPIRE_DATE"
          :label-for="datepickerId"
        >
          <gl-datepicker
            v-model="selectedDate"
            :input-id="datepickerId"
            class="gl-display-block!"
            :min-date="minDate"
            :target="null"
          />
        </gl-form-group>

        <slot name="form-after"></slot>
      </template>

      <template v-for="{ key } in extraSlots" #[key]>
        <slot :name="key"></slot>
      </template>
    </content-transition>

    <template #modal-footer>
      <div
        class="gl-m-0 gl-xs-w-full gl-display-flex gl-xs-flex-direction-column! gl-flex-direction-row-reverse"
      >
        <gl-button
          class="gl-xs-w-full gl-xs-mb-3! gl-sm-ml-3!"
          data-testid="invite-modal-submit"
          v-bind="actionPrimary.attributes"
          @click="onSubmit"
        >
          {{ actionPrimary.text }}
        </gl-button>

        <gl-button
          class="gl-xs-w-full"
          data-testid="invite-modal-cancel"
          v-bind="actionCancel.attributes"
          @click="onCancel"
        >
          {{ actionCancel.text }}
        </gl-button>
      </div>
    </template>
  </gl-modal>
</template>
