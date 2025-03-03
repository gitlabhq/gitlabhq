<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';
import { I18N_DELETE } from '../constants';
import RunnerDeleteAction from './runner_delete_action.vue';

export default {
  name: 'RunnerDeleteDisclosureDropdownItem',
  components: {
    GlDisclosureDropdownItem,
    RunnerDeleteAction,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
  },
  emits: ['deleted'],
  methods: {
    onDone(event) {
      this.$emit('deleted', event);
    },
  },
  I18N_DELETE,
};
</script>

<template>
  <runner-delete-action :runner="runner" @done="onDone">
    <template #default="{ onClick }">
      <gl-disclosure-dropdown-item variant="danger" @action="onClick">
        <template #list-item>
          {{ $options.I18N_DELETE }}
        </template>
      </gl-disclosure-dropdown-item>
    </template>
  </runner-delete-action>
</template>
