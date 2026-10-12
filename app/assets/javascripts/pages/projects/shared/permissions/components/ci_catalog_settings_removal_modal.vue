<script>
import { GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { __, formatNumber, n__, s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

import getCiCatalogResourceUsageQuery from '~/ci/catalog/graphql/queries/get_ci_catalog_resource_usage.query.graphql';

export default {
  name: 'CiCatalogSettingsRemovalModal',
  components: {
    GlLink,
    GlModal,
    GlSprintf,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['close', 'primary'],
  data() {
    return {
      usageCount: null,
    };
  },
  apollo: {
    usageCount: {
      query: getCiCatalogResourceUsageQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update({ ciCatalogResource }) {
        return ciCatalogResource?.last30DayUsageCount ?? null;
      },
      error() {
        this.usageCount = null;
      },
    },
  },
  computed: {
    hasUsageCount() {
      return this.usageCount !== null;
    },
    usageMessage() {
      return sprintf(
        n__(
          'CiCatalog|This component is used in %{boldStart}%{count}%{boldEnd} project.',
          'CiCatalog|This component is used in %{boldStart}%{count}%{boldEnd} projects.',
          this.usageCount,
        ),
        { count: formatNumber(this.usageCount) },
      );
    },
  },
  actionPrimary: { text: s__('CiCatalog|Remove from the CI/CD catalog') },
  actionCancel: { text: __('Cancel') },
  releasesHelpPath: helpPagePath('user/project/releases/release_cicd_examples'),
};
</script>

<template>
  <gl-modal
    visible
    modal-id="unlist-catalog-resource"
    size="sm"
    :title="s__('CiCatalog|Remove component project from the CI/CD Catalog?')"
    :action-cancel="$options.actionCancel"
    :action-primary="$options.actionPrimary"
    @hidden="$emit('close')"
    @primary="$emit('primary')"
  >
    <p data-testid="removal-details">
      <gl-sprintf v-if="hasUsageCount" :message="usageMessage">
        <template #bold="{ content }">
          <strong>{{ content }}</strong>
        </template>
      </gl-sprintf>
      {{
        s__(
          'CiCatalog|The project and any released versions will be removed from the CI/CD Catalog.',
        )
      }}
    </p>
    <p class="gl-mb-0">
      <gl-sprintf
        :message="
          s__(
            'CiCatalog|If you re-add this component later, the project\'s previous releases are not restored. You must %{linkStart}create a new release%{linkEnd}.',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.releasesHelpPath" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
