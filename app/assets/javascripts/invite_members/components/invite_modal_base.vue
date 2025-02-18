<script>
import { GlFormGroup, GlModal, GlDatepicker, GlLink, GlSprintf, GlButton } from '@gitlab/ui';

import Tracking from '~/tracking';
import { sprintf } from '~/locale';
import ContentTransition from '~/invite_members/components/content_transition.vue';
import { initialSelectedRole, roleDropdownItems } from 'ee_else_ce/members/utils';
import RoleSelector from '~/members/components/role_selector.vue';
import {
  ACCESS_LEVEL,
  ACCESS_EXPIRE_DATE,
  READ_MORE_TEXT,
  READ_MORE_ACCESS_EXPIRATION_TEXT,
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
    RoleSelector,
    GlFormGroup,
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
    defaultMemberRoleId: {
      type: Number,
      required: false,
      default: null,
    },
    helpLink: {
      type: String,
      required: true,
    },
    accessExpirationHelpLink: {
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
    isLoadingRoles: {
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
      selectedRole: null,
      selectedDate: undefined,
      minDate: new Date(),
    };
  },
  computed: {
    roleDropdownItems() {
      return roleDropdownItems(this.accessLevels);
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
    roleDropdownItems: {
      immediate: true,
      handler() {
        this.resetSelectedAccessLevel();
      },
    },
  },
  methods: {
    onReset() {
      // This component isn't necessarily disposed, so we might need to reset its state.
      this.resetSelectedAccessLevel();
      this.selectedDate = undefined;

      this.$emit('reset');
    },
    onShowModal() {
      this.$emit('shown');
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
    onSubmit() {
      this.$emit('submit', {
        accessLevel: this.selectedRole.accessLevel,
        memberRoleId: this.selectedRole.memberRoleId,
        expiresAt: this.selectedDate,
      });
    },
    onClose() {
      this.$emit('close');
    },
    resetSelectedAccessLevel() {
      const accessLevel = {
        integerValue: this.defaultAccessLevel,
        memberRoleId: this.defaultMemberRoleId,
      };
      this.selectedRole = initialSelectedRole(this.roleDropdownItems.flatten, { accessLevel });
    },
  },
  HEADER_CLOSE_LABEL,
  ACCESS_EXPIRE_DATE,
  ACCESS_LEVEL,
  READ_MORE_TEXT,
  READ_MORE_ACCESS_EXPIRATION_TEXT,
  INVITE_BUTTON_TEXT,
  CANCEL_BUTTON_TEXT,
  DEFAULT_SLOT,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
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
      class="gl-grid"
      transition-name="invite-modal-transition"
      :slots="contentSlots"
      :current-slot="currentSlot"
    >
      <template #[$options.DEFAULT_SLOT]>
        <div class="gl-flex" data-testid="modal-base-intro-text">
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

        <slot name="after-members-input"></slot>

        <gl-form-group :label="$options.ACCESS_LEVEL" :label-for="dropdownId">
          <template #description>
            <gl-sprintf :message="$options.READ_MORE_TEXT">
              <template #link="{ content }">
                <gl-link :href="helpLink" target="_blank" data-testid="invite-modal-help-link">{{
                  content
                }}</gl-link>
              </template>
            </gl-sprintf>
          </template>

          <role-selector
            v-model="selectedRole"
            data-testid="access-level-dropdown"
            :roles="roleDropdownItems"
            :loading="isLoadingRoles"
            class="gl-max-w-30"
            header-text=""
          />
        </gl-form-group>

        <gl-form-group :label="$options.ACCESS_EXPIRE_DATE" :label-for="datepickerId">
          <gl-datepicker
            v-model="selectedDate"
            :input-id="datepickerId"
            class="!gl-block"
            :min-date="minDate"
            :target="null"
          />
          <template #description>
            <gl-sprintf :message="$options.READ_MORE_ACCESS_EXPIRATION_TEXT">
              <template #link="{ content }">
                <gl-link
                  :href="accessExpirationHelpLink"
                  target="_blank"
                  data-testid="invite-modal-access-expiration-link"
                  >{{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </template>
        </gl-form-group>
      </template>

      <template v-for="{ key } in extraSlots" #[key]>
        <slot :name="key"></slot>
      </template>
    </content-transition>

    <template #modal-footer>
      <div class="gl-m-0 gl-flex gl-w-full gl-flex-col sm:gl-flex-row-reverse">
        <gl-button
          class="gl-w-full sm:!gl-ml-3 sm:gl-w-auto"
          data-testid="invite-modal-submit"
          v-bind="actionPrimary.attributes"
          @click.prevent="onSubmit"
        >
          {{ actionPrimary.text }}
        </gl-button>

        <gl-button
          class="gl-w-full sm:gl-w-auto"
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
