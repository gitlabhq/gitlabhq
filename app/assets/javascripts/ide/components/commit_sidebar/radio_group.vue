<script>
import {
  GlTooltipDirective,
  GlFormRadio,
  GlFormRadioGroup,
  GlFormGroup,
  GlFormInput,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';

export default {
  components: {
    GlFormRadio,
    GlFormRadioGroup,
    GlFormGroup,
    GlFormInput,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: false,
      default: null,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
    showInput: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState('commit', ['commitAction', 'newBranchName']),
    ...mapGetters('commit', ['placeholderBranchName']),
    tooltipTitle() {
      return this.disabled ? this.title : '';
    },
  },
  methods: {
    ...mapActions('commit', ['updateCommitAction', 'updateBranchName']),
  },
};
</script>

<template>
  <fieldset class="gl-mb-2">
    <gl-form-radio-group
      v-gl-tooltip="tooltipTitle"
      :checked="commitAction"
      :class="{
        'is-disabled': disabled,
      }"
    >
      <gl-form-radio
        :value="value"
        :disabled="disabled"
        name="commit-action"
        @change="updateCommitAction(value)"
      >
        <span v-if="label" class="ide-option-label">
          {{ label }}
        </span>
        <slot v-else></slot>
      </gl-form-radio>
    </gl-form-radio-group>

    <gl-form-group
      v-if="commitAction === value && showInput"
      :label="placeholderBranchName"
      :label-sr-only="true"
      class="gl-mb-0 gl-ml-6"
    >
      <gl-form-input
        :placeholder="placeholderBranchName"
        :value="newBranchName"
        :disabled="disabled"
        data-testid="ide-new-branch-name"
        class="gl-font-monospace"
        @input="updateBranchName($event)"
      />
    </gl-form-group>
  </fieldset>
</template>
