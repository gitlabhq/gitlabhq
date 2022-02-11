<script>
import {
  GlFormGroup,
  GlModal,
  GlDropdown,
  GlDropdownItem,
  GlDatepicker,
  GlLink,
  GlSprintf,
  GlButton,
  GlFormInput,
} from '@gitlab/ui';
import { unescape } from 'lodash';
import { sanitize } from '~/lib/dompurify';
import { sprintf } from '~/locale';
import {
  ACCESS_LEVEL,
  ACCESS_EXPIRE_DATE,
  INVALID_FEEDBACK_MESSAGE_DEFAULT,
  READ_MORE_TEXT,
  INVITE_BUTTON_TEXT,
  CANCEL_BUTTON_TEXT,
  HEADER_CLOSE_LABEL,
} from '../constants';
import { responseMessageFromError } from '../utils/response_message_parser';

export default {
  components: {
    GlFormGroup,
    GlDatepicker,
    GlLink,
    GlModal,
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    GlButton,
    GlFormInput,
  },
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
  },
  data() {
    // Be sure to check out reset!
    return {
      invalidFeedbackMessage: '',
      selectedAccessLevel: this.defaultAccessLevel,
      selectedDate: undefined,
      isLoading: false,
      minDate: new Date(),
    };
  },
  computed: {
    introText() {
      return sprintf(this.labelIntroText, { name: this.name });
    },
    validationState() {
      return this.invalidFeedbackMessage ? false : null;
    },
    selectLabelId() {
      return `${this.modalId}_select`;
    },
    selectedRoleName() {
      return Object.keys(this.accessLevels).find(
        (key) => this.accessLevels[key] === Number(this.selectedAccessLevel),
      );
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
    showInvalidFeedbackMessage(response) {
      const message = this.unescapeMsg(responseMessageFromError(response));

      this.invalidFeedbackMessage = message || INVALID_FEEDBACK_MESSAGE_DEFAULT;
    },
    reset() {
      // This component isn't necessarily disposed,
      // so we might need to reset it's state.
      this.isLoading = false;
      this.invalidFeedbackMessage = '';
      this.selectedAccessLevel = this.defaultAccessLevel;
      this.selectedDate = undefined;

      this.$emit('reset');
    },
    closeModal() {
      this.reset();
      this.$refs.modal.hide();
    },
    clearValidation() {
      this.invalidFeedbackMessage = '';
    },
    changeSelectedItem(item) {
      this.selectedAccessLevel = item;
    },
    submit() {
      this.isLoading = true;
      this.invalidFeedbackMessage = '';

      this.$emit('submit', {
        onSuccess: () => {
          this.isLoading = false;
        },
        onError: (...args) => {
          this.isLoading = false;
          this.showInvalidFeedbackMessage(...args);
        },
        data: {
          accessLevel: this.selectedAccessLevel,
          expiresAt: this.selectedDate,
        },
      });
    },
    unescapeMsg(message) {
      return unescape(sanitize(message, { ALLOWED_TAGS: [] }));
    },
  },
  HEADER_CLOSE_LABEL,
  ACCESS_EXPIRE_DATE,
  ACCESS_LEVEL,
  READ_MORE_TEXT,
  INVITE_BUTTON_TEXT,
  CANCEL_BUTTON_TEXT,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    data-qa-selector="invite_members_modal_content"
    data-testid="invite-modal"
    size="sm"
    :title="modalTitle"
    :header-close-label="$options.HEADER_CLOSE_LABEL"
    @hidden="reset"
    @close="reset"
    @hide="reset"
  >
    <div class="gl-display-flex" data-testid="modal-base-intro-text">
      <slot name="intro-text-before"></slot>
      <p>
        <gl-sprintf :message="introText">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </p>
      <slot name="intro-text-after"></slot>
    </div>

    <gl-form-group
      :invalid-feedback="invalidFeedbackMessage"
      :state="validationState"
      :description="formGroupDescription"
      data-testid="members-form-group"
    >
      <label :id="selectLabelId" class="col-form-label">{{ labelSearchField }}</label>
      <slot
        name="select"
        v-bind="{ clearValidation, validationState, labelId: selectLabelId }"
      ></slot>
    </gl-form-group>

    <label class="gl-font-weight-bold">{{ $options.ACCESS_LEVEL }}</label>
    <div class="gl-mt-2 gl-w-half gl-xs-w-full">
      <gl-dropdown
        class="gl-shadow-none gl-w-full"
        data-qa-selector="access_level_dropdown"
        v-bind="$attrs"
        :text="selectedRoleName"
      >
        <template v-for="(key, item) in accessLevels">
          <gl-dropdown-item
            :key="key"
            active-class="is-active"
            is-check-item
            :is-checked="key === selectedAccessLevel"
            @click="changeSelectedItem(key)"
          >
            <div>{{ item }}</div>
          </gl-dropdown-item>
        </template>
      </gl-dropdown>
    </div>

    <div class="gl-mt-2 gl-w-half gl-xs-w-full">
      <gl-sprintf :message="$options.READ_MORE_TEXT">
        <template #link="{ content }">
          <gl-link :href="helpLink" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </div>

    <label class="gl-mt-5 gl-display-block" for="expires_at">{{
      $options.ACCESS_EXPIRE_DATE
    }}</label>
    <div class="gl-mt-2 gl-w-half gl-xs-w-full gl-display-inline-block">
      <gl-datepicker
        v-model="selectedDate"
        class="gl-display-inline!"
        :min-date="minDate"
        :target="null"
      >
        <template #default="{ formattedDate }">
          <gl-form-input class="gl-w-full" :value="formattedDate" :placeholder="__(`YYYY-MM-DD`)" />
        </template>
      </gl-datepicker>
    </div>
    <slot name="form-after"></slot>

    <template #modal-footer>
      <gl-button data-testid="cancel-button" @click="closeModal">
        {{ $options.CANCEL_BUTTON_TEXT }}
      </gl-button>
      <gl-button
        :disabled="submitDisabled"
        :loading="isLoading"
        variant="success"
        data-qa-selector="invite_button"
        data-testid="invite-button"
        @click="submit"
      >
        {{ $options.INVITE_BUTTON_TEXT }}
      </gl-button>
    </template>
  </gl-modal>
</template>
