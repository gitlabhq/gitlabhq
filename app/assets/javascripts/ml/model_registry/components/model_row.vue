<script>
import { GlLink, GlTruncate } from '@gitlab/ui';
import { s__, n__ } from '~/locale';
import ListItem from '~/vue_shared/components/registry/list_item.vue';

export default {
  name: 'MlModelRow',
  components: {
    GlLink,
    ListItem,
    GlTruncate,
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasVersions() {
      return this.model.versionCount > 0;
    },
    modelVersionCountMessage() {
      if (!this.model.versionCount) return s__('MlModelRegistry|No registered versions');

      return n__(
        'MlModelRegistry|· %d version',
        'MlModelRegistry|· %d versions',
        this.model.versionCount,
      );
    },
  },
};
</script>

<template>
  <list-item v-bind="$attrs">
    <template #left-primary>
      <div class="gl-display-flex gl-align-items-center">
        <gl-link class="gl-text-body" :href="model._links.showPath">
          <gl-truncate :text="model.name" />
        </gl-link>
      </div>
    </template>

    <template #left-secondary>
      <div class="gl-text-secondary">
        <gl-link v-if="hasVersions" :href="model.latestVersion._links.showPath">{{
          model.latestVersion.version
        }}</gl-link>

        {{ modelVersionCountMessage }}
      </div>
    </template>
  </list-item>
</template>
