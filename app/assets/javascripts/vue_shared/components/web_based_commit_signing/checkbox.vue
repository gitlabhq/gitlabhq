<script>
import { GlFormCheckbox, GlAlert } from '@gitlab/ui';
import GroupInheritancePopover from '~/vue_shared/components/settings/group_inheritance_popover.vue';
import { __ } from '~/locale';

export default {
  name: 'WebBasedCommitSigningCheckbox',
  components: {
    GlFormCheckbox,
    GlAlert,
    GroupInheritancePopover,
  },
  props: {
    initialValue: {
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
    groupWebBasedCommitSigningEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    // eslint-disable-next-line vue/no-unused-properties
    fullPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isChecked: this.initialValue,
      isSaving: false,
      errorMessage: '',
    };
  },
  computed: {
    isDisabled() {
      return this.isSaving || (!this.isGroupLevel && this.groupWebBasedCommitSigningEnabled);
    },
  },
  methods: {
    async handleChange(value) {
      this.isChecked = value;
      this.errorMessage = '';
      this.isSaving = true;

      //   TODO: Implement GraphQL mutation and side effects
      // try {
      //   const mutation = this.isGroupLevel
      //     ? updateGroupWebBasedCommitSigningMutation
      //     : updateProjectWebBasedCommitSigningMutation;

      //   const response = await this.$apollo.mutate({
      //     mutation,
      //     variables: {
      //       fullPath: this.fullPath,
      //       webBasedCommitSigningEnabled: value,
      //     },
      //   });
      // } catch (error) {
      //   this.errorMessage = error.message || __('An error occurred while updating the setting.');
      //   this.isChecked = !value;
      // } finally {
      //   this.isSaving = false;
      // }
    },
    dismissError() {
      this.errorMessage = '';
    },
  },
  i18n: {
    label: __('Sign web-based commits'),
    description: __('Automatically sign commits made through the web interface.'),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="errorMessage" variant="danger" class="gl-mb-5" @dismiss="dismissError">
      {{ errorMessage }}
    </gl-alert>

    <gl-form-checkbox
      id="web-based-commit-signing-checkbox"
      :checked="isChecked"
      :disabled="isDisabled"
      @change="handleChange"
      ><span class="gl-inline-flex">
        {{ $options.i18n.label }}
        <group-inheritance-popover
          v-if="!isGroupLevel"
          class="gl-relative gl-bottom-2"
          :has-group-permissions="hasGroupPermissions"
          :group-settings-repository-path="groupSettingsRepositoryPath"
        />
      </span>
      <template #help>{{ $options.i18n.description }}</template>
    </gl-form-checkbox>
  </div>
</template>
