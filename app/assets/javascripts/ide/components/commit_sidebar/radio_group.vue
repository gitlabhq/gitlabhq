<script>
import { mapActions, mapState, mapGetters } from 'vuex';
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
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState('commit', ['commitAction']),
    ...mapGetters('commit', ['newBranchName']),
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
      v-tooltip
      :title="tooltipTitle"
      :class="{
        'is-disabled': disabled
      }"
    >
      <input
        :value="value"
        :checked="commitAction === value"
        :disabled="disabled"
        type="radio"
        name="commit-action"
        @change="updateCommitAction($event.target.value)"
      />
      <span class="prepend-left-10">
        <span
          v-if="label"
          class="ide-radio-label"
        >
          {{ label }}
        </span>
        <slot v-else></slot>
      </span>
    </label>
    <div
      v-if="commitAction === value && showInput"
      class="ide-commit-new-branch"
    >
      <input
        :placeholder="newBranchName"
        type="text"
        class="form-control monospace"
        @input="updateBranchName($event.target.value)"
      />
    </div>
  </fieldset>
</template>
