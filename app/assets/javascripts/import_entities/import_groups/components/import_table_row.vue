<script>
import {
  GlButton,
  GlDropdownDivider,
  GlDropdownItem,
  GlDropdownSectionHeader,
  GlIcon,
  GlLink,
  GlFormInput,
} from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import ImportGroupDropdown from '../../components/group_dropdown.vue';
import ImportStatus from '../../components/import_status.vue';
import { STATUSES } from '../../constants';
import addValidationErrorMutation from '../graphql/mutations/add_validation_error.mutation.graphql';
import removeValidationErrorMutation from '../graphql/mutations/remove_validation_error.mutation.graphql';
import groupAndProjectQuery from '../graphql/queries/groupAndProject.query.graphql';

const DEBOUNCE_INTERVAL = 300;

export default {
  components: {
    ImportStatus,
    ImportGroupDropdown,
    GlButton,
    GlDropdownDivider,
    GlDropdownItem,
    GlDropdownSectionHeader,
    GlLink,
    GlIcon,
    GlFormInput,
  },
  props: {
    group: {
      type: Object,
      required: true,
    },
    availableNamespaces: {
      type: Array,
      required: true,
    },
    groupPathRegex: {
      type: RegExp,
      required: true,
    },
  },

  apollo: {
    existingGroupAndProject: {
      query: groupAndProjectQuery,
      debounce: DEBOUNCE_INTERVAL,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ existingGroup, existingProject }) {
        const variables = {
          field: 'new_name',
          sourceGroupId: this.group.id,
        };

        if (!existingGroup && !existingProject) {
          this.$apollo.mutate({
            mutation: removeValidationErrorMutation,
            variables,
          });
        } else {
          this.$apollo.mutate({
            mutation: addValidationErrorMutation,
            variables: {
              ...variables,
              message: this.$options.i18n.NAME_ALREADY_EXISTS,
            },
          });
        }
      },
      skip() {
        return !this.isNameValid || this.isAlreadyImported;
      },
    },
  },

  computed: {
    availableNamespaceNames() {
      return this.availableNamespaces.map((ns) => ns.full_path);
    },

    importTarget() {
      return this.group.import_target;
    },

    invalidNameValidationMessage() {
      return this.group.validation_errors.find(({ field }) => field === 'new_name')?.message;
    },

    isInvalid() {
      return Boolean(!this.isNameValid || this.invalidNameValidationMessage);
    },

    isNameValid() {
      return this.groupPathRegex.test(this.importTarget.new_name);
    },

    isAlreadyImported() {
      return this.group.progress.status !== STATUSES.NONE;
    },

    isFinished() {
      return this.group.progress.status === STATUSES.FINISHED;
    },

    fullPath() {
      return `${this.importTarget.target_namespace}/${this.importTarget.new_name}`;
    },

    absolutePath() {
      return joinPaths(gon.relative_url_root || '/', this.fullPath);
    },
  },

  i18n: {
    NAME_ALREADY_EXISTS: s__('BulkImport|Name already exists.'),
  },
};
</script>

<template>
  <tr
    class="gl-border-gray-200 gl-border-0 gl-border-b-1 gl-border-solid"
    data-qa-selector="import_item"
    :data-qa-source-group="group.full_path"
  >
    <td class="gl-p-4">
      <gl-link
        :href="group.web_url"
        target="_blank"
        class="gl-display-flex gl-align-items-center gl-h-7"
      >
        {{ group.full_path }} <gl-icon name="external-link" />
      </gl-link>
    </td>
    <td class="gl-p-4">
      <gl-link
        v-if="isFinished"
        class="gl-display-flex gl-align-items-center gl-h-7"
        :href="absolutePath"
      >
        {{ fullPath }}
      </gl-link>

      <div
        v-else
        class="import-entities-target-select gl-display-flex gl-align-items-stretch"
        :class="{
          disabled: isAlreadyImported,
        }"
      >
        <import-group-dropdown
          #default="{ namespaces }"
          :text="importTarget.target_namespace"
          :disabled="isAlreadyImported"
          :namespaces="availableNamespaceNames"
          toggle-class="gl-rounded-top-right-none! gl-rounded-bottom-right-none!"
          class="import-entities-namespace-dropdown gl-h-7 gl-flex-grow-1"
          data-qa-selector="target_namespace_selector_dropdown"
        >
          <gl-dropdown-item @click="$emit('update-target-namespace', '')">{{
            s__('BulkImport|No parent')
          }}</gl-dropdown-item>
          <template v-if="namespaces.length">
            <gl-dropdown-divider />
            <gl-dropdown-section-header>
              {{ s__('BulkImport|Existing groups') }}
            </gl-dropdown-section-header>
            <gl-dropdown-item
              v-for="ns in namespaces"
              :key="ns"
              data-qa-selector="target_group_dropdown_item"
              :data-qa-group-name="ns"
              @click="$emit('update-target-namespace', ns)"
            >
              {{ ns }}
            </gl-dropdown-item>
          </template>
        </import-group-dropdown>
        <div
          class="import-entities-target-select-separator gl-h-7 gl-px-3 gl-display-flex gl-align-items-center gl-border-solid gl-border-0 gl-border-t-1 gl-border-b-1"
        >
          /
        </div>
        <div class="gl-flex-grow-1">
          <gl-form-input
            class="gl-rounded-top-left-none gl-rounded-bottom-left-none"
            :class="{ 'is-invalid': isInvalid && !isAlreadyImported }"
            :disabled="isAlreadyImported"
            :value="importTarget.new_name"
            @input="$emit('update-new-name', $event)"
          />
          <p v-if="isInvalid" class="gl-text-red-500 gl-m-0 gl-mt-2">
            <template v-if="!isNameValid">
              {{ __('Please choose a group URL with no special characters.') }}
            </template>
            <template v-else-if="invalidNameValidationMessage">
              {{ invalidNameValidationMessage }}
            </template>
          </p>
        </div>
      </div>
    </td>
    <td class="gl-p-4 gl-white-space-nowrap" data-qa-selector="import_status_indicator">
      <import-status :status="group.progress.status" class="gl-mt-2" />
    </td>
    <td class="gl-p-4">
      <gl-button
        v-if="!isAlreadyImported"
        :disabled="isInvalid"
        variant="confirm"
        category="secondary"
        data-qa-selector="import_group_button"
        @click="$emit('import-group')"
        >{{ __('Import') }}</gl-button
      >
    </td>
  </tr>
</template>
