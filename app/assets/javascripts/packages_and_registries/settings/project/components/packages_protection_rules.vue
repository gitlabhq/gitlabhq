<script>
import { GlCard, GlTable, GlLoadingIcon } from '@gitlab/ui';
import packagesProtectionRuleQuery from '~/packages_and_registries/settings/project/graphql/queries/get_packages_protection_rules.query.graphql';
import SettingsBlock from '~/packages_and_registries/shared/components/settings_block.vue';
import { s__ } from '~/locale';

const PAGINATION_DEFAULT_PER_PAGE = 10;

export default {
  components: {
    SettingsBlock,
    GlCard,
    GlTable,
    GlLoadingIcon,
  },
  inject: ['projectPath'],
  i18n: {
    settingBlockTitle: s__('PackageRegistry|Protected packages'),
    settingBlockDescription: s__(
      'PackageRegistry|When a package is protected then only certain user roles are able to update and delete the protected package. This helps to avoid tampering with the package.',
    ),
  },
  data() {
    return {
      fetchSettingsError: false,
      packageProtectionRules: [],
    };
  },
  computed: {
    tableItems() {
      return this.packageProtectionRules.map((packagesProtectionRule) => {
        return {
          col_1_package_name_pattern: packagesProtectionRule.packageNamePattern,
          col_2_package_type: packagesProtectionRule.packageType,
          col_3_push_protected_up_to_access_level:
            packagesProtectionRule.pushProtectedUpToAccessLevel,
        };
      });
    },
    totalItems() {
      return this.packageProtectionRules.length;
    },
  },
  apollo: {
    packageProtectionRules: {
      query: packagesProtectionRuleQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          first: PAGINATION_DEFAULT_PER_PAGE,
        };
      },
      update: (data) => {
        return data.project?.packagesProtectionRules?.nodes || [];
      },
      error(e) {
        this.fetchSettingsError = e;
      },
    },
  },
  fields: [
    {
      key: 'col_1_package_name_pattern',
      label: s__('PackageRegistry|Package name pattern'),
    },
    { key: 'col_2_package_type', label: s__('PackageRegistry|Package type') },
    {
      key: 'col_3_push_protected_up_to_access_level',
      label: s__('PackageRegistry|Push protected up to access level'),
    },
  ],
};
</script>

<template>
  <settings-block>
    <template #title>{{ $options.i18n.settingBlockTitle }}</template>

    <template #description>
      {{ $options.i18n.settingBlockDescription }}
    </template>

    <template #default>
      <gl-card
        class="gl-new-card"
        header-class="gl-new-card-header"
        body-class="gl-new-card-body gl-px-0"
      >
        <template #header>
          <div class="gl-new-card-title-wrapper gl-justify-content-space-between">
            <h3 class="gl-new-card-title">{{ $options.i18n.settingBlockTitle }}</h3>
          </div>
        </template>

        <template #default>
          <gl-table
            :items="tableItems"
            :fields="$options.fields"
            show-empty
            stacked="md"
            class="mb-3"
          >
            <template #table-busy>
              <gl-loading-icon size="sm" class="gl-my-5" />
            </template>
          </gl-table>
        </template>
      </gl-card>
    </template>
  </settings-block>
</template>
