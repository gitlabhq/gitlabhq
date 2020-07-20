<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';

export default {
  components: {
    GlLink,
    GlSprintf,
  },
  computed: {
    ...mapState(['ancestorHelperPath', 'hasAncestorClusters']),
  },
};
</script>

<template>
  <div v-if="hasAncestorClusters" class="bs-callout bs-callout-info">
    <p>
      <gl-sprintf
        :message="
          s__(
            'ClusterIntegration|Clusters are utilized by selecting the nearest ancestor with a matching environment scope. For example, project clusters will override group clusters. %{linkStart}More information%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="ancestorHelperPath">
            <strong>{{ content }}</strong>
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
  </div>
</template>
