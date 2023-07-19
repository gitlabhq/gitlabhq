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
      <gl-disclosure-dropdown-item @action="onClick">
        <template #list-item>
          <span class="gl-text-red-500">{{ $options.I18N_DELETE }}</span>
        </template>
      </gl-disclosure-dropdown-item>
    </template>
  </runner-delete-action>
</template>
