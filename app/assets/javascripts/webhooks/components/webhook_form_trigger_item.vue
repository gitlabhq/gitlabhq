<script>
import { GlFormCheckbox, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  name: 'WebhookFormTriggerItem',
  components: {
    GlFormCheckbox,
    GlLink,
  },
  props: {
    value: {
      type: Boolean,
      required: false,
      default: false,
    },
    triggerName: {
      type: String,
      required: true,
    },
    inputName: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    helpText: {
      type: String,
      required: false,
      default: null,
    },
    helpLinkText: {
      type: String,
      required: false,
      default: null,
    },
    helpLinkPath: {
      type: String,
      required: false,
      default: null,
    },
    helpLinkAnchor: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['input'],
  computed: {
    id() {
      return `webhooks-${this.triggerName}`;
    },
    helpLinkUrl() {
      if (!this.helpLinkPath || !this.helpLinkText) return null;
      // eslint-disable-next-line local-rules/require-valid-help-page-path
      return helpPagePath(this.helpLinkPath, { anchor: this.helpLinkAnchor });
    },
  },
  methods: {
    handleInput(newValue) {
      this.$emit('input', newValue);
    },
  },
};
</script>

<template>
  <div>
    <gl-form-checkbox
      :id="id"
      :checked="value"
      :name="inputName"
      class="gl-mt-3"
      @input="handleInput"
    >
      {{ label }}
      <template v-if="helpText" #help>
        {{ helpText }}
        <gl-link v-if="helpLinkUrl" :href="helpLinkUrl" target="_blank">
          {{ helpLinkText }}
        </gl-link>
      </template>
    </gl-form-checkbox>
    <input type="hidden" :name="inputName" :value="value ? '1' : '0'" />
  </div>
</template>
