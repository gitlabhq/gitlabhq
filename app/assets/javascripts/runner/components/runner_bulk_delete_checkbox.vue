<script>
import { GlFormCheckbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import checkedRunnerIdsQuery from '../graphql/list/checked_runner_ids.query.graphql';

export default {
  components: {
    GlFormCheckbox,
  },
  inject: ['localMutations'],
  props: {
    runners: {
      type: Array,
      default: () => [],
      required: false,
    },
  },
  data() {
    return {
      checkedRunnerIds: [],
    };
  },
  apollo: {
    checkedRunnerIds: {
      query: checkedRunnerIdsQuery,
    },
  },
  computed: {
    disabled() {
      return !this.runners.length;
    },
    checked() {
      return Boolean(this.runners.length) && this.runners.every(this.isChecked);
    },
    indeterminate() {
      return !this.checked && this.runners.some(this.isChecked);
    },
    label() {
      return this.checked ? s__('Runners|Unselect all') : s__('Runners|Select all');
    },
  },
  methods: {
    isChecked({ id }) {
      return this.checkedRunnerIds.indexOf(id) >= 0;
    },
    onChange($event) {
      this.localMutations.setRunnersChecked({
        runners: this.runners,
        isChecked: $event,
      });
    },
  },
};
</script>

<template>
  <gl-form-checkbox
    :aria-label="label"
    :indeterminate="indeterminate"
    :checked="checked"
    :disabled="disabled"
    @change="onChange"
  />
</template>
