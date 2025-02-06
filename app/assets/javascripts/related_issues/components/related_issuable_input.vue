<script>
import { GlFormGroup } from '@gitlab/ui';
import $ from 'jquery';
import GfmAutoComplete from 'ee_else_ce/gfm_auto_complete';
import { TYPE_ISSUE } from '~/issues/constants';
import {
  autoCompleteTextMap,
  inputPlaceholderConfidentialTextMap,
  inputPlaceholderTextMap,
} from '../constants';
import { ENTER_KEY, TAB_KEY } from '../../lib/utils/keys';
import IssueToken from './issue_token.vue';

const SPACE_FACTOR = 1;

export default {
  name: 'RelatedIssuableInput',
  components: {
    GlFormGroup,
    IssueToken,
  },
  props: {
    inputId: {
      type: String,
      required: false,
      default: '',
    },
    references: {
      type: Array,
      required: false,
      default: () => [],
    },
    pathIdSeparator: {
      type: String,
      required: true,
    },
    inputValue: {
      type: String,
      required: false,
      default: '',
    },
    focusOnMount: {
      type: Boolean,
      required: false,
      default: false,
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    autoCompleteOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
    confidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    inline: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isInputFocused: false,
      isAutoCompleteOpen: false,
      areEventsAssigned: false,
    };
  },
  computed: {
    inputPlaceholder() {
      const { issuableType, allowAutoComplete, confidential } = this;
      const inputPlaceholderMapping = confidential
        ? inputPlaceholderConfidentialTextMap
        : inputPlaceholderTextMap;
      const allowAutoCompleteText = autoCompleteTextMap[allowAutoComplete][issuableType];
      return `${inputPlaceholderMapping[issuableType]}${allowAutoCompleteText}`;
    },
    allowAutoComplete() {
      return Object.keys(this.autoCompleteSources).length > 0;
    },
    showDescription() {
      return !this.inline && this.issuableType === TYPE_ISSUE;
    },
  },
  mounted() {
    this.setupAutoComplete();
    if (this.focusOnMount) {
      this.$nextTick()
        .then(() => {
          this.$refs.input.focus();
        })
        .catch(() => {});
    }
  },
  beforeUpdate() {
    this.setupAutoComplete();
  },
  beforeDestroy() {
    const $input = $(this.$refs.input);
    // eslint-disable-next-line @gitlab/no-global-event-off
    $input.off('shown-issues.atwho');
    // eslint-disable-next-line @gitlab/no-global-event-off
    $input.off('hidden-issues.atwho');
    $input.off('inserted-issues.atwho', this.onInput);
  },
  methods: {
    onAutoCompleteToggled(isOpen) {
      this.isAutoCompleteOpen = isOpen;
    },
    onInput() {
      const { value } = this.$refs.input;
      const caretPos = this.$refs.input.selectionStart;
      const rawRefs = value.split(/\s/);
      let touchedReference;
      let position = 0;

      const untouchedRawRefs = rawRefs
        .filter((ref) => {
          let isTouched = false;

          if (caretPos >= position && caretPos <= position + ref.length) {
            touchedReference = ref;
            isTouched = true;
          }

          position = position + ref.length + SPACE_FACTOR;

          return !isTouched;
        })
        .filter((ref) => ref.trim().length > 0);

      this.$emit('addIssuableFormInput', {
        newValue: value,
        untouchedRawReferences: untouchedRawRefs,
        touchedReference,
        caretPos,
      });
    },
    onBlur(event) {
      // Early exit if this Blur event is caused by card header
      const container = this.$root.$el.querySelector('.js-button-container');
      if (container && container.contains(event.relatedTarget)) {
        return;
      }

      this.isInputFocused = false;

      // Avoid tokenizing partial input when clicking an autocomplete item
      if (!this.isAutoCompleteOpen) {
        const { value } = this.$refs.input;
        // Avoid event emission when only pathIdSeparator has been typed
        if (value !== this.pathIdSeparator) {
          this.$emit('addIssuableFormBlur', value);
        }
      }
    },
    onFocus() {
      this.isInputFocused = true;
    },
    onKeydown(event) {
      if ([ENTER_KEY, TAB_KEY].includes(event.key)) {
        const { value } = this.$refs.input;

        this.$emit('addIssuableFinishEntry', { value, event });
      }
    },
    setupAutoComplete() {
      const $input = $(this.$refs.input);

      if (this.allowAutoComplete) {
        this.gfmAutoComplete = new GfmAutoComplete(this.autoCompleteSources);
        this.gfmAutoComplete.setup($input, this.autoCompleteOptions);
      }

      if (!this.areEventsAssigned) {
        $input.on('shown-issues.atwho', this.onAutoCompleteToggled.bind(this, true));
        $input.on('hidden-issues.atwho', this.onAutoCompleteToggled.bind(this, true));
      }
      this.areEventsAssigned = true;
    },
    onIssuableFormWrapperClick() {
      this.$refs.input.focus();
    },
  },
};
</script>

<template>
  <gl-form-group :label-class="inline ? 'gl-hidden' : ''">
    <div
      ref="issuableFormWrapper"
      :class="{ focus: isInputFocused }"
      class="add-issuable-form-input-wrapper form-control gl-field-error-outline gl-h-auto gl-px-3 gl-pb-0 gl-pt-2"
      @click="onIssuableFormWrapperClick"
    >
      <ul class="gl-m-0 gl-flex gl-list-none gl-flex-wrap gl-items-baseline gl-p-0">
        <li
          v-for="(reference, index) in references"
          :key="reference"
          class="gl-mb-2 gl-mr-2 gl-max-w-full"
        >
          <issue-token
            :id-key="index"
            :display-reference="reference.text || reference"
            can-remove
            is-condensed
            :path-id-separator="pathIdSeparator"
            event-namespace="pendingIssuable"
            @pendingIssuableRemoveRequest="
              (params) => {
                $emit('pendingIssuableRemoveRequest', params);
              }
            "
          />
        </li>
        <li class="gl-mb-2 gl-grow">
          <input
            :id="inputId"
            ref="input"
            :aria-describedby="`${inputId}-description`"
            :value="inputValue"
            :placeholder="inputPlaceholder"
            :aria-label="inputPlaceholder"
            type="text"
            class="gl-w-full gl-border-none gl-outline-none"
            data-testid="add-issue-field"
            autocomplete="off"
            @input="onInput"
            @focus="onFocus"
            @blur="onBlur"
            @keydown="onKeydown"
            @keyup.escape.exact="$emit('addIssuableFormCancel')"
          />
        </li>
      </ul>
    </div>
    <template v-if="showDescription" #description>
      <span :id="`${inputId}-description`">
        {{
          __(
            'Only issues can be linked from this form. You can also link this issue from an epic or task.',
          )
        }}
      </span>
    </template>
  </gl-form-group>
</template>
