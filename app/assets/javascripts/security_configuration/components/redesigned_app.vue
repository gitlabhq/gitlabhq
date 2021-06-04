<script>
import { GlTab, GlTabs, GlSprintf, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import FeatureCard from './feature_card.vue';
import SectionLayout from './section_layout.vue';

export const i18n = {
  compliance: s__('SecurityConfiguration|Compliance'),
  securityTesting: s__('SecurityConfiguration|Security testing'),
  securityTestingDescription: s__(
    `SecurityConfiguration|The status of the tools only applies to the
      default branch and is based on the %{linkStart}latest pipeline%{linkEnd}.
      Once you've enabled a scan for the default branch, any subsequent feature
      branch you create will include the scan.`,
  ),
  securityConfiguration: __('Security Configuration'),
};

export default {
  i18n,
  components: {
    GlTab,
    GlLink,
    GlTabs,
    GlSprintf,
    FeatureCard,
    SectionLayout,
  },
  props: {
    augmentedSecurityFeatures: {
      type: Array,
      required: true,
    },
    augmentedComplianceFeatures: {
      type: Array,
      required: true,
    },

    latestPipelinePath: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <article>
    <header>
      <h1 class="gl-font-size-h1">{{ $options.i18n.securityConfiguration }}</h1>
    </header>

    <gl-tabs content-class="gl-pt-6">
      <gl-tab data-testid="security-testing-tab" :title="$options.i18n.securityTesting">
        <section-layout :heading="$options.i18n.securityTesting">
          <template #description>
            <p
              v-if="latestPipelinePath"
              data-testid="latest-pipeline-info-security"
              class="gl-line-height-20"
            >
              <gl-sprintf :message="$options.i18n.securityTestingDescription">
                <template #link="{ content }">
                  <gl-link :href="latestPipelinePath">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </p>
          </template>

          <template #features>
            <feature-card
              v-for="feature in augmentedSecurityFeatures"
              :key="feature.type"
              :feature="feature"
              class="gl-mb-6"
            />
          </template>
        </section-layout>
      </gl-tab>
      <gl-tab data-testid="compliance-testing-tab" :title="$options.i18n.compliance">
        <section-layout :heading="$options.i18n.compliance">
          <template #description>
            <p
              v-if="latestPipelinePath"
              class="gl-line-height-20"
              data-testid="latest-pipeline-info-compliance"
            >
              <gl-sprintf :message="$options.i18n.securityTestingDescription">
                <template #link="{ content }">
                  <gl-link :href="latestPipelinePath">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </p>
          </template>
          <template #features>
            <feature-card
              v-for="feature in augmentedComplianceFeatures"
              :key="feature.type"
              :feature="feature"
              class="gl-mb-6"
            />
          </template>
        </section-layout>
      </gl-tab>
    </gl-tabs>
  </article>
</template>
