<script>
import { GlSprintf, GlLink, GlAlert } from '@gitlab/ui';
import DuplicatesSettings from '~/packages_and_registries/settings/group/components/duplicates_settings.vue';
import GenericSettings from '~/packages_and_registries/settings/group/components/generic_settings.vue';
import MavenSettings from '~/packages_and_registries/settings/group/components/maven_settings.vue';
import {
  PACKAGE_SETTINGS_HEADER,
  PACKAGE_SETTINGS_DESCRIPTION,
  PACKAGES_DOCS_PATH,
  ERROR_UPDATING_SETTINGS,
  SUCCESS_UPDATING_SETTINGS,
} from '~/packages_and_registries/settings/group/constants';
import updateNamespacePackageSettings from '~/packages_and_registries/settings/group/graphql/mutations/update_group_packages_settings.mutation.graphql';
import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import { updateGroupPackageSettings } from '~/packages_and_registries/settings/group/graphql/utils/cache_update';
import { updateGroupPackagesSettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

export default {
  name: 'GroupSettingsApp',
  i18n: {
    PACKAGE_SETTINGS_HEADER,
    PACKAGE_SETTINGS_DESCRIPTION,
  },
  links: {
    PACKAGES_DOCS_PATH,
  },
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    SettingsBlock,
    MavenSettings,
    GenericSettings,
    DuplicatesSettings,
  },
  inject: ['defaultExpanded', 'groupPath'],
  apollo: {
    packageSettings: {
      query: getGroupPackagesSettingsQuery,
      variables() {
        return {
          fullPath: this.groupPath,
        };
      },
      update(data) {
        return data.group?.packageSettings;
      },
    },
  },
  data() {
    return {
      packageSettings: {},
      errors: {},
      alertMessage: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.packageSettings.loading;
    },
  },
  methods: {
    dismissAlert() {
      this.alertMessage = null;
    },
    updateSettings(payload) {
      this.errors = {};
      return this.$apollo
        .mutate({
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
        })
        .then(({ data }) => {
          if (data.updateNamespacePackageSettings?.errors?.length > 0) {
            this.alertMessage = ERROR_UPDATING_SETTINGS;
          } else {
            this.dismissAlert();
            this.$toast.show(SUCCESS_UPDATING_SETTINGS);
          }
        })
        .catch((e) => {
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
          this.alertMessage = ERROR_UPDATING_SETTINGS;
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="alertMessage" variant="warning" class="gl-mt-4" @dismiss="dismissAlert">
      {{ alertMessage }}
    </gl-alert>

    <settings-block
      :default-expanded="defaultExpanded"
      data-qa-selector="package_registry_settings_content"
    >
      <template #title> {{ $options.i18n.PACKAGE_SETTINGS_HEADER }}</template>
      <template #description>
        <span data-testid="description">
          <gl-sprintf :message="$options.i18n.PACKAGE_SETTINGS_DESCRIPTION">
            <template #link="{ content }">
              <gl-link :href="$options.links.PACKAGES_DOCS_PATH" target="_blank">{{
                content
              }}</gl-link>
            </template>
          </gl-sprintf>
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
  </div>
</template>
