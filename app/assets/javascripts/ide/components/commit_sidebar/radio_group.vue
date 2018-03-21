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
      helpText: {
        type: String,
        required: false,
        default: null,
      },
    },
    computed: {
      ...mapState('commit', [
        'commitAction',
      ]),
      ...mapGetters('commit', [
        'newBranchName',
      ]),
    },
    methods: {
      ...mapActions('commit', [
        'updateCommitAction',
        'updateBranchName',
      ]),
    },
  };
</script>

<template>
  <fieldset>
    <label>
      <input
        type="radio"
        name="commit-action"
        :value="value"
        @change="updateCommitAction($event.target.value)"
        :checked="checked"
        v-once
      />
      <span class="prepend-left-10">
        <template v-if="label">
          {{ label }}
        </template>
        <slot v-else></slot>
        <span
          v-if="helpText"
          v-tooltip
          class="help-block inline"
          :title="helpText"
        >
          <i
            class="fa fa-question-circle"
            aria-hidden="true"
          >
          </i>
        </span>
      </span>
    </label>
    <div
      v-if="commitAction === value && showInput"
      class="ide-commit-new-branch"
    >
      <input
        type="text"
        class="form-control"
        :placeholder="newBranchName"
        @input="updateBranchName($event.target.value)"
      />
    </div>
  </fieldset>
</template>
