<script>
import { GlToggle, GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import updateDependencyProxySettings from '~/packages_and_registries/settings/group/graphql/mutations/update_dependency_proxy_settings.mutation.graphql';
import { updateGroupPackageSettings } from '~/packages_and_registries/settings/group/graphql/utils/cache_update';
import { updateGroupDependencyProxySettingsOptimisticResponse } from '~/packages_and_registries/settings/group/graphql/utils/optimistic_responses';

import {
  DEPENDENCY_PROXY_HEADER,
  DEPENDENCY_PROXY_SETTINGS_DESCRIPTION,
  DEPENDENCY_PROXY_DOCS_PATH,
} from '~/packages_and_registries/settings/group/constants';

export default {
  name: 'DependencyProxySettings',
  components: {
    GlToggle,
    GlSprintf,
    GlLink,
    SettingsBlock,
  },
  i18n: {
    DEPENDENCY_PROXY_HEADER,
    DEPENDENCY_PROXY_SETTINGS_DESCRIPTION,
    label: s__('DependencyProxy|Enable Dependency Proxy'),
    enabledProxyHelpText: s__(
      'DependencyProxy|To see the image prefix and what is in the cache, visit the %{linkStart}Dependency Proxy%{linkEnd}',
    ),
  },
  links: {
    DEPENDENCY_PROXY_DOCS_PATH,
  },
  inject: ['defaultExpanded', 'groupPath', 'groupDependencyProxyPath'],
  props: {
    dependencyProxySettings: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    enabled: {
      get() {
        return this.dependencyProxySettings.enabled;
      },
      set(enabled) {
        this.updateSettings({ enabled });
      },
    },
    helpText() {
      return this.enabled ? this.$options.i18n.enabledProxyHelpText : '';
    },
  },
  methods: {
    async updateSettings(payload) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateDependencyProxySettings,
          variables: {
            input: {
              groupPath: this.groupPath,
              ...payload,
            },
          },
          update: updateGroupPackageSettings(this.groupPath),
          optimisticResponse: updateGroupDependencyProxySettingsOptimisticResponse({
            ...this.dependencyProxySettings,
            ...payload,
          }),
        });

        if (data.updateDependencyProxySettings?.errors?.length > 0) {
          throw new Error();
        } else {
          this.$emit('success');
        }
      } catch {
        this.$emit('error');
      }
    },
  },
};
</script>

<template>
  <settings-block
    :default-expanded="defaultExpanded"
    data-qa-selector="dependency_proxy_settings_content"
  >
    <template #title> {{ $options.i18n.DEPENDENCY_PROXY_HEADER }} </template>
    <template #description>
      <span data-testid="description">
        <gl-sprintf :message="$options.i18n.DEPENDENCY_PROXY_SETTINGS_DESCRIPTION">
          <template #docLink="{ content }">
            <gl-link
              data-testid="description-link"
              :href="$options.links.DEPENDENCY_PROXY_DOCS_PATH"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </span>
    </template>
    <template #default>
      <div>
        <gl-toggle
          v-model="enabled"
          :disabled="isLoading"
          :label="$options.i18n.label"
          :help="helpText"
          data-qa-selector="dependency_proxy_setting_toggle"
          data-testid="dependency-proxy-setting-toggle"
        >
          <template #help>
            <span class="gl-overflow-break-word gl-max-w-100vw gl-display-inline-block">
              <gl-sprintf :message="$options.i18n.enabledProxyHelpText">
                <template #link="{ content }">
                  <gl-link data-testid="toggle-help-link" :href="groupDependencyProxyPath">{{
                    content
                  }}</gl-link>
                </template>
              </gl-sprintf>
            </span>
          </template>
        </gl-toggle>
      </div>
    </template>
  </settings-block>
</template>
