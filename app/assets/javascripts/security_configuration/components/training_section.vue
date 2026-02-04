<script>
import { GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import SectionLayout from '~/vue_shared/security_configuration/components/section_layout.vue';
import FeatureCard from './feature_card.vue';
import TrainingProviderList from './training_provider_list.vue';

export default {
  name: 'TrainingSection',
  components: {
    GlLink,
    SectionLayout,
    FeatureCard,
    TrainingProviderList,
  },
  inject: ['vulnerabilityTrainingDocsPath'],
  props: {
    isFeatureAvailableOnCurrentTier: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    featureNotAvailableContent() {
      return {
        name: s__('SecurityConfiguration|Security training'),
        description: s__(
          'SecurityConfiguration|Enable security training to help your developers learn how to fix vulnerabilities.',
        ),
        helpPath: this.vulnerabilityTrainingDocsPath,
        type: 'security_training',
        available: false,
        configured: false,
      };
    },
  },
};
</script>

<template>
  <div>
    <feature-card
      v-if="!isFeatureAvailableOnCurrentTier"
      :feature="featureNotAvailableContent"
      class="gl-mt-4"
    />
    <section-layout
      v-else
      stacked
      :heading="s__('SecurityConfiguration|Security training')"
      data-testid="security-training-section"
    >
      <template #description>
        <p>
          {{
            s__(
              'SecurityConfiguration|Enable security training to help your developers learn how to fix vulnerabilities. Developers can view security training from selected educational providers, relevant to the detected vulnerability. Please note that security training is not accessible in an environment that is offline.',
            )
          }}
        </p>
        <p>
          <gl-link :href="vulnerabilityTrainingDocsPath">{{
            s__('SecurityConfiguration|Learn more about vulnerability training')
          }}</gl-link>
        </p>
      </template>
      <template #features>
        <training-provider-list />
      </template>
    </section-layout>
  </div>
</template>
