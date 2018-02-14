<script>
  import { mapActions, mapState, mapGetters } from 'vuex';

  export default {
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
      </span>
    </label>
    <div
      v-if="commitAction === value && showInput"
      class="prepend-left-20"
    >
      <input
        type="text"
        class="form-control input-sm"
        :placeholder="newBranchName"
        @input="updateBranchName($event.target.value)"
      />
    </div>
  </fieldset>
</template>
