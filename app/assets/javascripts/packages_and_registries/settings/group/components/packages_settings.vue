<script>
import { GlTableLite, GlToggle } from '@gitlab/ui';
import {
  GENERIC_PACKAGE_FORMAT,
  MAVEN_PACKAGE_FORMAT,
  NUGET_PACKAGE_FORMAT,
  TERRAFORM_MODULE_PACKAGE_FORMAT,
  PACKAGE_FORMATS_TABLE_HEADER,
  PACKAGE_SETTINGS_HEADER,
  PACKAGE_SETTINGS_DESCRIPTION,
  DUPLICATES_SETTING_EXCEPTION_TITLE,
  DUPLICATES_TOGGLE_LABEL,
} from '~/packages_and_registries/settings/group/constants';
import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import { updateGroupPackageSettings } from '~/packages_and_registries/settings/group/graphql/utils/cache_update';
import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import ExceptionsInput from '~/packages_and_registries/settings/group/components/exceptions_input.vue';

export default {
  name: 'PackageSettings',
  i18n: {
    PACKAGE_SETTINGS_HEADER,
    PACKAGE_SETTINGS_DESCRIPTION,
    DUPLICATES_SETTING_EXCEPTION_TITLE,
    DUPLICATES_TOGGLE_LABEL,
  },
  tableHeaderFields: [
    {
      key: 'packageFormat',
      label: PACKAGE_FORMATS_TABLE_HEADER,
      thClass: '!gl-bg-subtle',
    },
    {
      key: 'allowDuplicates',
      label: DUPLICATES_TOGGLE_LABEL,
      thClass: '!gl-bg-subtle',
    },
    {
      key: 'exceptions',
      label: DUPLICATES_SETTING_EXCEPTION_TITLE,
      thClass: '!gl-bg-subtle',
    },
  ],
  components: {
    SettingsSection,
    GlTableLite,
    GlToggle,
    ExceptionsInput,
  },
  inject: ['groupPath'],
  props: {
    packageSettings: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      errors: {},
    };
  },
  computed: {
    tableRows() {
      return [
        {
          id: 'maven-duplicated-settings-regex-input',
          format: MAVEN_PACKAGE_FORMAT,
          duplicatesAllowed: this.packageSettings.mavenDuplicatesAllowed,
          duplicateExceptionRegex: this.packageSettings.mavenDuplicateExceptionRegex,
          duplicateExceptionRegexError: this.errors.mavenDuplicateExceptionRegex,
          modelNames: {
            allowed: 'mavenDuplicatesAllowed',
            exception: 'mavenDuplicateExceptionRegex',
          },
          testid: 'maven-settings',
        },
        {
          id: 'generic-duplicated-settings-regex-input',
          format: GENERIC_PACKAGE_FORMAT,
          duplicatesAllowed: this.packageSettings.genericDuplicatesAllowed,
          duplicateExceptionRegex: this.packageSettings.genericDuplicateExceptionRegex,
          duplicateExceptionRegexError: this.errors.genericDuplicateExceptionRegex,
          modelNames: {
            allowed: 'genericDuplicatesAllowed',
            exception: 'genericDuplicateExceptionRegex',
          },
          testid: 'generic-settings',
        },
        {
          id: 'nuget-duplicated-settings-regex-input',
          format: NUGET_PACKAGE_FORMAT,
          duplicatesAllowed: this.packageSettings.nugetDuplicatesAllowed,
          duplicateExceptionRegex: this.packageSettings.nugetDuplicateExceptionRegex,
          duplicateExceptionRegexError: this.errors.nugetDuplicateExceptionRegex,
          modelNames: {
            allowed: 'nugetDuplicatesAllowed',
            exception: 'nugetDuplicateExceptionRegex',
          },
          testid: 'nuget-settings',
        },
        {
          id: 'terraform-module-duplicated-settings-regex-input',
          format: TERRAFORM_MODULE_PACKAGE_FORMAT,
          duplicatesAllowed: this.packageSettings.terraformModuleDuplicatesAllowed,
          duplicateExceptionRegex: this.packageSettings.terraformModuleDuplicateExceptionRegex,
          duplicateExceptionRegexError: this.errors.terraformModuleDuplicateExceptionRegex,
          modelNames: {
            allowed: 'terraformModuleDuplicatesAllowed',
            exception: 'terraformModuleDuplicateExceptionRegex',
          },
          testid: 'terraform-module-settings',
        },
      ];
    },
  },
  methods: {
    async updateSettings(payload) {
      this.errors = {};
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateNamespacePackageSettings,
          variables: {
            input: {
              namespacePath: this.groupPath,
              ...payload,
            },
          },
          update: updateGroupPackageSettings(this.groupPath),
          optimisticResponse: updateGroupPackagesSettingsOptimisticResponse({
            ...this.packageSettings,
            ...payload,
          }),
        });

        if (data.updateNamespacePackageSettings?.errors?.length > 0) {
          throw new Error();
        } else {
          this.$emit('success');
        }
      } catch (e) {
        if (e.graphQLErrors) {
          e.graphQLErrors.forEach((error) => {
            const [
              {
                path: [key],
                message,
              },
            ] = error.extensions.problems;
            this.errors = { ...this.errors, [key]: message };
          });
        }
        this.$emit('error');
      }
    },
    update(type, value) {
      this.updateSettings({ [type]: value });
    },
  },
};
</script>

<template>
  <settings-section
    :heading="$options.i18n.PACKAGE_SETTINGS_HEADER"
    :description="$options.i18n.PACKAGE_SETTINGS_DESCRIPTION"
    data-testid="package-registry-settings-content"
  >
    <form>
      <gl-table-lite
        :fields="$options.tableHeaderFields"
        :items="tableRows"
        stacked="sm"
        :tbody-tr-attr="(item) => ({ 'data-testid': item.testid })"
      >
        <template #cell(packageFormat)="{ item }">
          <span class="md:gl-pt-3">{{ item.format }}</span>
        </template>
        <template #cell(allowDuplicates)="{ item }">
          <gl-toggle
            :data-testid="item.dataTestid"
            :label="$options.i18n.DUPLICATES_TOGGLE_LABEL"
            :value="item.duplicatesAllowed"
            :disabled="isLoading"
            label-position="hidden"
            class="gl-items-end sm:gl-items-start"
            @change="update(item.modelNames.allowed, $event)"
          />
        </template>
        <template #cell(exceptions)="{ item }">
          <exceptions-input
            :id="item.id"
            :duplicate-exception-regex="item.duplicateExceptionRegex"
            :duplicate-exception-regex-error="item.duplicateExceptionRegexError"
            :name="item.modelNames.exception"
            :loading="isLoading"
            @update="updateSettings"
          />
        </template>
      </gl-table-lite>
    </form>
  </settings-section>
</template>
