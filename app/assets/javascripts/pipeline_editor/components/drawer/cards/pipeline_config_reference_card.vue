<script>
import { GlCard, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  i18n: {
    title: s__('PipelineEditorTutorial|⚙️ Pipeline configuration reference'),
    firstParagraph: s__('PipelineEditorTutorial|Resources to help with your CI/CD configuration:'),
    browseExamples: s__(
      'PipelineEditorTutorial|Browse %{linkStart}CI/CD examples and templates%{linkEnd}',
    ),
    viewSyntaxRef: s__(
      'PipelineEditorTutorial|View %{linkStart}.gitlab-ci.yml syntax reference%{linkEnd}',
    ),
    learnMore: s__(
      'PipelineEditorTutorial|Learn more about %{linkStart}GitLab CI/CD concepts%{linkEnd}',
    ),
    needs: s__(
      'PipelineEditorTutorial|Make your pipeline more efficient with the %{linkStart}Needs keyword%{linkEnd}',
    ),
  },
  components: {
    GlCard,
    GlLink,
    GlSprintf,
  },
  inject: ['ciExamplesHelpPagePath', 'ciHelpPagePath', 'needsHelpPagePath', 'ymlHelpPagePath'],
};
</script>
<template>
  <gl-card>
    <template #default>
      <h4 class="gl-font-lg gl-mt-0">{{ $options.i18n.title }}</h4>
      <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
      <ul>
        <li>
          <gl-sprintf :message="$options.i18n.browseExamples">
            <template #link="{ content }">
              <gl-link :href="ciExamplesHelpPagePath" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </li>
        <li>
          <gl-sprintf :message="$options.i18n.viewSyntaxRef">
            <template #link="{ content }">
              <gl-link :href="ymlHelpPagePath" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </li>
        <li>
          <gl-sprintf :message="$options.i18n.learnMore">
            <template #link="{ content }">
              <gl-link :href="ciHelpPagePath" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </li>
        <li>
          <gl-sprintf :message="$options.i18n.needs">
            <template #link="{ content }">
              <gl-link :href="needsHelpPagePath" target="_blank">
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </li>
      </ul>
    </template>
  </gl-card>
</template>
