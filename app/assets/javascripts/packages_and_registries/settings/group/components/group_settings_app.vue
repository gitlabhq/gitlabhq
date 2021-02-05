<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';

import {
  PACKAGE_SETTINGS_HEADER,
  PACKAGE_SETTINGS_DESCRIPTION,
  PACKAGES_DOCS_PATH,
} from '../constants';
import getGroupPackagesSettingsQuery from '../graphql/queries/get_group_packages_settings.query.graphql';

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
    GlSprintf,
    GlLink,
    SettingsBlock,
  },
  inject: {
    defaultExpanded: {
      type: Boolean,
      default: false,
      required: true,
    },
    groupPath: {
      type: String,
      required: true,
    },
  },
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
    };
  },
};
</script>

<template>
  <div>
    <settings-block :default-expanded="defaultExpanded">
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
    </settings-block>
  </div>
</template>
