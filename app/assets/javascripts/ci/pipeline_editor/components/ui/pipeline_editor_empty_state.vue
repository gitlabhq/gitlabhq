<script>
import { GlButton, GlCard, GlEmptyState } from '@gitlab/ui';
import ROCKET_ILLUSTRATION from '@gitlab/svgs/dist/illustrations/rocket-launch-md.svg?url';
import DuoAnalyzeCard from 'ee_component/ci/pipeline_editor/components/ui/duo_analyze_card.vue';
import glAbilitiesMixin from '~/vue_shared/mixins/gl_abilities_mixin';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';
import { exploreCatalogIndexPath } from '~/lib/utils/path_helpers/explore';

export default {
  name: 'PipelineEditorEmptyState',
  components: {
    DuoAnalyzeCard,
    ExternalConfigEmptyState,
    GlButton,
    GlCard,
    GlEmptyState,
  },
  mixins: [glAbilitiesMixin()],
  inject: ['usesExternalConfig', 'newPipelinePath'],
  emits: ['create-empty-config-file'],
  emptyStateIllustrationPath: ROCKET_ILLUSTRATION,
  computed: {
    exploreCatalogIndexPath() {
      return exploreCatalogIndexPath();
    },
  },
  methods: {
    createEmptyConfigFile() {
      this.$emit('create-empty-config-file');
    },
  },
};
</script>
<template>
  <div>
    <external-config-empty-state v-if="usesExternalConfig" :new-pipeline-path="newPipelinePath" />
    <gl-empty-state
      v-else
      :title="__('Get up and running with GitLab CI/CD')"
      :svg-path="$options.emptyStateIllustrationPath"
      :svg-height="144"
      content-class="gl-max-w-full"
    >
      <template #description>
        {{ __('Streamline your development process effortlessly with robust CI/CD pipelines.') }}
      </template>
    </gl-empty-state>
    <div class="gl-w-max-full container-limited gl-mx-auto gl-grid gl-gap-5 lg:gl-grid-cols-3">
      <duo-analyze-card v-if="glAbilities.accessDuoAgenticChat" />
      <gl-card body-class="gl-flex gl-flex-col">
        <template #header>
          <h2 class="gl-heading-scale-300 gl-mb-0">{{ s__('Pipelines|Use a CI/CD component') }}</h2>
        </template>
        <template #default>
          <p class="gl-grow">
            {{ s__('Pipelines|Start with a pre-built and customizable CI/CD component.') }}
          </p>
          <gl-button :href="exploreCatalogIndexPath" data-testid="browse-catalog-button">
            {{ s__('Pipelines|Browse catalog') }}
          </gl-button>
        </template>
      </gl-card>
      <gl-card body-class="gl-flex gl-flex-col">
        <template #header>
          <h2 class="gl-heading-scale-300 gl-mb-0">{{ s__('Pipelines|Write your own') }}</h2>
        </template>
        <template #default>
          <p class="gl-grow">
            {{
              s__('Pipelines|Write your own CI/CD configuration by hand, starting from scratch.')
            }}
          </p>
          <gl-button data-testid="create-new-ci-button" @click="createEmptyConfigFile">
            {{ s__('Pipelines|Start building') }}
          </gl-button>
        </template>
      </gl-card>
    </div>
  </div>
</template>
<style>
.gl-border-bottom-none {
  border-bottom-style: none;
}
</style>
