<script>
import DuplicatesSettings from '~/packages_and_registries/settings/group/components/duplicates_settings.vue';
import GenericSettings from '~/packages_and_registries/settings/group/components/generic_settings.vue';
import MavenSettings from '~/packages_and_registries/settings/group/components/maven_settings.vue';
import {
  PACKAGE_SETTINGS_HEADER,
  PACKAGE_SETTINGS_DESCRIPTION,
} from '~/packages_and_registries/settings/group/constants';
import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import { updateGroupPackageSettings } from '~/packages_and_registries/settings/group/graphql/utils/cache_update';
import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';

export default {
  name: 'PackageSettings',
  i18n: {
    PACKAGE_SETTINGS_HEADER,
    PACKAGE_SETTINGS_DESCRIPTION,
  },
  components: {
    SettingsBlock,
    MavenSettings,
    GenericSettings,
    DuplicatesSettings,
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
  },
};
</script>

<template>
  <settings-block data-qa-selector="package_registry_settings_content">
    <template #title> {{ $options.i18n.PACKAGE_SETTINGS_HEADER }}</template>
    <template #description>
      <span data-testid="description">
        {{ $options.i18n.PACKAGE_SETTINGS_DESCRIPTION }}
      </span>
    </template>
    <template #default>
      <maven-settings data-testid="maven-settings">
        <template #default="{ modelNames }">
          <duplicates-settings
            :duplicates-allowed="packageSettings.mavenDuplicatesAllowed"
            :duplicate-exception-regex="packageSettings.mavenDuplicateExceptionRegex"
            :duplicate-exception-regex-error="errors.mavenDuplicateExceptionRegex"
            :model-names="modelNames"
            :loading="isLoading"
            toggle-qa-selector="allow_duplicates_toggle"
            label-qa-selector="allow_duplicates_label"
            @update="updateSettings"
          />
        </template>
      </maven-settings>
      <generic-settings class="gl-mt-6" data-testid="generic-settings">
        <template #default="{ modelNames }">
          <duplicates-settings
            :duplicates-allowed="packageSettings.genericDuplicatesAllowed"
            :duplicate-exception-regex="packageSettings.genericDuplicateExceptionRegex"
            :duplicate-exception-regex-error="errors.genericDuplicateExceptionRegex"
            :model-names="modelNames"
            :loading="isLoading"
            @update="updateSettings"
          />
        </template>
      </generic-settings>
    </template>
  </settings-block>
</template>
