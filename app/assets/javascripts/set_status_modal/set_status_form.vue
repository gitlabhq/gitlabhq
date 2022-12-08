<script>
import {
  GlButton,
  GlTooltipDirective,
  GlIcon,
  GlFormCheckbox,
  GlFormInput,
  GlFormInputGroup,
  GlDropdown,
  GlDropdownItem,
  GlFormGroup,
} from '@gitlab/ui';
import $ from 'jquery';
import SafeHtml from '~/vue_shared/directives/safe_html';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import * as Emoji from '~/emoji';
import { s__ } from '~/locale';
import { formatDate, newDate, nSecondsAfter, isToday } from '~/lib/utils/datetime_utility';
import { TIME_RANGES_WITH_NEVER, AVAILABILITY_STATUS, NEVER_TIME_RANGE } from './constants';

export default {
  components: {
    GlButton,
    GlIcon,
    GlFormCheckbox,
    GlFormInput,
    GlFormInputGroup,
    GlDropdown,
    GlDropdownItem,
    GlFormGroup,
    EmojiPicker: () => import('~/emoji/components/picker.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    defaultEmoji: {
      type: String,
      required: false,
      default: '',
    },
    emoji: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    availability: {
      type: Boolean,
      required: true,
    },
    clearStatusAfter: {
      type: Object,
      required: false,
      default: null,
    },
    currentClearStatusAfter: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      defaultEmojiTag: '',
      emojiTag: '',
    };
  },
  computed: {
    isCustomEmoji() {
      return this.emoji !== this.defaultEmoji;
    },
    isDirty() {
      return Boolean(this.message.length || this.isCustomEmoji);
    },
    noEmoji() {
      return this.emojiTag === '';
    },
    clearStatusAfterDropdownText() {
      if (this.clearStatusAfter === null && this.currentClearStatusAfter.length) {
        return this.formatClearStatusAfterDate(new Date(this.currentClearStatusAfter));
      }

      if (this.clearStatusAfter?.duration?.seconds) {
        const clearStatusAfterDate = nSecondsAfter(
          newDate(),
          this.clearStatusAfter.duration.seconds,
        );
        return this.formatClearStatusAfterDate(clearStatusAfterDate);
      }

      return NEVER_TIME_RANGE.label;
    },
  },
  mounted() {
    this.setupEmojiListAndAutocomplete();
  },
  methods: {
    async setupEmojiListAndAutocomplete() {
      const emojiAutocomplete = new GfmAutoComplete();
      emojiAutocomplete.setup($(this.$refs.statusMessageField.$el), { emojis: true });

      if (this.emoji) {
        this.emojiTag = Emoji.glEmojiTag(this.emoji);
      }
      this.defaultEmojiTag = Emoji.glEmojiTag(this.defaultEmoji);

      this.setDefaultEmoji();
    },
    setDefaultEmoji() {
      const { emojiTag } = this;
      const hasStatusMessage = Boolean(this.message.length);
      if (hasStatusMessage && emojiTag) {
        return;
      }

      if (hasStatusMessage) {
        this.emojiTag = this.defaultEmojiTag;
      } else if (emojiTag === this.defaultEmojiTag) {
        this.clearEmoji();
      }
    },
    handleEmojiClick(emoji) {
      this.$emit('emoji-click', emoji);

      this.emojiTag = Emoji.glEmojiTag(emoji);
    },
    clearEmoji() {
      if (this.emojiTag) {
        this.emojiTag = '';
      }
    },
    clearStatusInputs() {
      this.$emit('emoji-click', '');
      this.$emit('message-input', '');
      this.clearEmoji();
    },
    formatClearStatusAfterDate(date) {
      if (isToday(date)) {
        return formatDate(date, 'h:MMtt');
      }

      return formatDate(date, 'mmm d, yyyy h:MMtt');
    },
  },
  TIME_RANGES_WITH_NEVER,
  AVAILABILITY_STATUS,
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  i18n: {
    statusMessagePlaceholder: s__(`SetStatusModal|What's your status?`),
    clearStatusButtonLabel: s__('SetStatusModal|Clear status'),
    availabilityCheckboxLabel: s__('SetStatusModal|Set yourself as busy'),
    availabilityCheckboxHelpText: s__(
      'SetStatusModal|Displays that you are busy or not able to respond',
    ),
    clearStatusAfterDropdownLabel: s__('SetStatusModal|Clear status after'),
    clearStatusAfterMessage: s__('SetStatusModal|Your status resets on %{date}.'),
  },
};
</script>

<template>
  <div>
    <gl-form-input-group class="gl-mb-5">
      <gl-form-input
        ref="statusMessageField"
        :value="message"
        :placeholder="$options.i18n.statusMessagePlaceholder"
        @keyup="setDefaultEmoji"
        @input="$emit('message-input', $event)"
        @keyup.enter.prevent
      />
      <template #prepend>
        <emoji-picker
          dropdown-class="gl-h-full"
          toggle-class="btn emoji-menu-toggle-button gl-px-4! gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
          boundary="viewport"
          :right="false"
          @click="handleEmojiClick"
        >
          <template #button-content>
            <span v-if="noEmoji" class="gl-relative" data-testid="no-emoji-placeholder">
              <gl-icon name="slight-smile" class="award-control-icon-neutral" />
              <gl-icon name="smiley" class="award-control-icon-positive" />
              <gl-icon name="smile" class="award-control-icon-super-positive" />
            </span>
            <span v-else>
              <span
                v-safe-html:[$options.safeHtmlConfig]="emojiTag"
                data-testid="selected-emoji"
              ></span>
            </span>
          </template>
        </emoji-picker>
      </template>
      <template v-if="isDirty" #append>
        <gl-button
          v-gl-tooltip.bottom
          :title="$options.i18n.clearStatusButtonLabel"
          :aria-label="$options.i18n.clearStatusButtonLabel"
          icon="close"
          class="js-clear-user-status-button"
          @click="clearStatusInputs"
        />
      </template>
    </gl-form-input-group>

    <gl-form-checkbox
      :checked="availability"
      class="gl-mb-5"
      data-testid="user-availability-checkbox"
      @input="$emit('availability-input', $event)"
    >
      {{ $options.i18n.availabilityCheckboxLabel }}
      <template #help>
        {{ $options.i18n.availabilityCheckboxHelpText }}
      </template>
    </gl-form-checkbox>

    <gl-form-group :label="$options.i18n.clearStatusAfterDropdownLabel" class="gl-mb-0">
      <gl-dropdown
        block
        :text="clearStatusAfterDropdownText"
        data-testid="clear-status-at-dropdown"
        toggle-class="gl-mb-0 gl-form-input-md"
      >
        <gl-dropdown-item
          v-for="after in $options.TIME_RANGES_WITH_NEVER"
          :key="after.name"
          :data-testid="after.name"
          @click="$emit('clear-status-after-click', after)"
          >{{ after.label }}</gl-dropdown-item
        >
      </gl-dropdown>
    </gl-form-group>
  </div>
</template>
