<script>
import { GlFormCheckbox } from '@gitlab/ui';
import GroupInheritancePopover from '~/vue_shared/components/settings/group_inheritance_popover.vue';
import { __ } from '~/locale';

export default {
  name: 'WebBasedCommitSigningCheckbox',
  components: {
    GlFormCheckbox,
    GroupInheritancePopover,
  },
  props: {
    isChecked: {
      type: Boolean,
      required: true,
    },
    hasGroupPermissions: {
      type: Boolean,
      required: true,
    },
    groupSettingsRepositoryPath: {
      type: String,
      required: true,
    },
    isGroupLevel: {
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
  emits: ['update:isChecked'],
  methods: {
    handleChange(value) {
      this.$emit('update:isChecked', value);
    },
  },
  i18n: {
    label: __('Sign web-based commits'),
    description: __('Automatically sign commits made through the web interface.'),
  },
};
</script>

<template>
  <gl-form-checkbox
    id="web-based-commit-signing-checkbox"
    :checked="isChecked"
    :disabled="disabled"
    @change="handleChange"
    ><span class="gl-inline-flex">
      {{ $options.i18n.label }}
      <group-inheritance-popover
        v-if="isGroupLevel"
        class="gl-relative gl-bottom-2"
        :has-group-permissions="hasGroupPermissions"
        :group-settings-repository-path="groupSettingsRepositoryPath"
      />
    </span>
    <template #help>{{ $options.i18n.description }}</template>
  </gl-form-checkbox>
</template>
