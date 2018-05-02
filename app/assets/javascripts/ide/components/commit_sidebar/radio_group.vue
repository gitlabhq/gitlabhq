<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
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
  },
  computed: {
    ...mapState('commit', ['commitAction']),
    ...mapGetters('commit', ['newBranchName']),
    tooltipTitle() {
      return this.disabled
        ? __('This option is disabled while you still have unstaged changes')
        : '';
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
      v-tooltip
      :title="tooltipTitle"
    >
      <input
        type="radio"
        name="commit-action"
        :value="value"
        @change="updateCommitAction($event.target.value)"
        :checked="commitAction === value"
        :disabled="disabled"
      />
      <span class="prepend-left-10">
        <template v-if="label">
          {{ label }}
        </template>
        <slot v-else></slot>
      </span>
    </label>
    <div
      v-if="commitAction === value && showInput"
      class="ide-commit-new-branch"
    >
      <input
        type="text"
        class="form-control monospace"
        :placeholder="newBranchName"
        @input="updateBranchName($event.target.value)"
      />
    </div>
  </fieldset>
</template>
