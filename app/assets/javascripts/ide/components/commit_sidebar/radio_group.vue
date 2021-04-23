<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';

export default {
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
  <fieldset>
    <label
      v-gl-tooltip="tooltipTitle"
      :class="{
        'is-disabled': disabled,
      }"
    >
      <input
        :value="value"
        :checked="commitAction === value"
        :disabled="disabled"
        type="radio"
        name="commit-action"
        data-qa-selector="commit_type_radio"
        @change="updateCommitAction($event.target.value)"
      />
      <span class="gl-ml-3">
        <span v-if="label" class="ide-option-label"> {{ label }} </span> <slot v-else></slot>
      </span>
    </label>
    <div v-if="commitAction === value && showInput" class="ide-commit-new-branch">
      <input
        :placeholder="placeholderBranchName"
        :value="newBranchName"
        data-testid="ide-new-branch-name"
        type="text"
        class="form-control monospace"
        @input="updateBranchName($event.target.value)"
      />
    </div>
  </fieldset>
</template>
