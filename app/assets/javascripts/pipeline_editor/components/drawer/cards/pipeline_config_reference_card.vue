<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  CI_EXAMPLES_LINK,
  CI_HELP_LINK,
  CI_NEEDS_LINK,
  CI_YAML_LINK,
  pipelineEditorTrackingOptions,
} from '../../../constants';

export default {
  CI_EXAMPLES_LINK,
  CI_HELP_LINK,
  CI_NEEDS_LINK,
  CI_YAML_LINK,
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
    GlLink,
    GlSprintf,
  },
  mixins: [Tracking.mixin()],
  inject: ['ciExamplesHelpPagePath', 'ciHelpPagePath', 'needsHelpPagePath', 'ymlHelpPagePath'],
  methods: {
    trackHelpPageClick(key) {
      const { label, actions } = pipelineEditorTrackingOptions;
      this.track(actions.helpDrawerLinks[key], { label });
    },
  },
};
</script>
<template>
  <div>
    <h3 class="gl-font-lg gl-mt-0 gl-mb-5">{{ $options.i18n.title }}</h3>
    <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
    <ul>
      <li>
        <gl-sprintf :message="$options.i18n.browseExamples">
          <template #link="{ content }">
            <gl-link
              :href="ciExamplesHelpPagePath"
              target="_blank"
              @click="trackHelpPageClick($options.CI_EXAMPLES_LINK)"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </li>
      <li>
        <gl-sprintf :message="$options.i18n.viewSyntaxRef">
          <template #link="{ content }">
            <gl-link
              :href="ymlHelpPagePath"
              target="_blank"
              @click="trackHelpPageClick($options.CI_YAML_LINK)"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </li>
      <li>
        <gl-sprintf :message="$options.i18n.learnMore">
          <template #link="{ content }">
            <gl-link
              :href="ciHelpPagePath"
              target="_blank"
              @click="trackHelpPageClick($options.CI_HELP_LINK)"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </li>
      <li>
        <gl-sprintf :message="$options.i18n.needs">
          <template #link="{ content }">
            <gl-link
              :href="needsHelpPagePath"
              target="_blank"
              @click="trackHelpPageClick($options.CI_NEEDS_LINK)"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </li>
    </ul>
  </div>
</template>
