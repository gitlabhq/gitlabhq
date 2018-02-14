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
        required: true,
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
      {{ label }}
    </label>
    <template
      v-if="commitAction === value && showInput"
    >
      <input
        type="text"
        class="form-control input-sm"
        :placeholder="newBranchName"
        @input="updateBranchName($event.target.value)"
      />
    </template>
  </fieldset>
</template>
