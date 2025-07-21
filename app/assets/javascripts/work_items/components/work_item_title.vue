<script>
import { uniqueId } from 'lodash';
import { GlFormGroup, GlFormInput, GlFormCharacterCount } from '@gitlab/ui';
import { n__, __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { TITLE_LENGTH_MAX } from '../../issues/constants';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlFormCharacterCount,
  },
  directives: {
    SafeHtml,
  },
  i18n: {
    titleLabel: __('Title (required)'),
    requiredFieldFeedback: __('A title is required'),
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    titleHtml: {
      type: String,
      required: false,
      default: null,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    isValid: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      inputId: uniqueId('work-item-title-'),
    };
  },
  computed: {
    isTitleValid() {
      return this.workItemTitle.length <= TITLE_LENGTH_MAX;
    },
    workItemTitle() {
      return this.titleHtml || this.title;
    },
    invalidFeedback() {
      return this.isTitleValid ? this.$options.i18n.requiredFieldFeedback : '';
    },
  },
  methods: {
    overLimitText(count) {
      return n__('%d character over limit.', '%d characters over limit.', count);
    },
    emitField($event) {
      this.$emit('updateDraft', $event);
      this.$emit('isTitleValid', this.isTitleValid);
    },
  },
  TITLE_LENGTH_MAX,
};
</script>

<template>
  <gl-form-group
    v-if="isEditing"
    :label="$options.i18n.titleLabel"
    :label-for="inputId"
    :invalid-feedback="invalidFeedback"
    :state="isValid"
  >
    <gl-form-input
      :id="inputId"
      ref="workitemTitleField"
      class="gl-w-full"
      :value="title"
      :state="isValid"
      autofocus
      aria-describedby="character-count-text"
      data-testid="work-item-title-input"
      @keydown.meta.enter="$emit('updateWorkItem')"
      @keydown.ctrl.enter="$emit('updateWorkItem')"
      @input="emitField"
    />
    <template #description>
      <gl-form-character-count
        :value="title"
        :limit="$options.TITLE_LENGTH_MAX"
        count-text-id="character-count-text"
      >
        <template #over-limit-text="{ count }">{{ overLimitText(count) }}</template>
      </gl-form-character-count>
    </template>
  </gl-form-group>
  <component
    :is="isModal ? 'h2' : 'h1'"
    v-else
    data-testid="work-item-title"
    class="gl-heading-1 !gl-m-0 gl-w-full gl-wrap-anywhere"
  >
    <span v-safe-html="workItemTitle"></span>
  </component>
</template>
