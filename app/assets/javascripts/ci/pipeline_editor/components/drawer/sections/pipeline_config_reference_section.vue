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
import PipelineEditorDrawerSection from '../pipeline_editor_drawer_section.vue';

export default {
  CI_EXAMPLES_LINK,
  CI_HELP_LINK,
  CI_NEEDS_LINK,
  CI_YAML_LINK,
  i18n: {
    title: s__('PipelineEditorTutorial|Pipeline configuration reference'),
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
    PipelineEditorDrawerSection,
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
  <pipeline-editor-drawer-section emoji="gear" :title="$options.i18n.title">
    <p class="gl-mb-3">{{ $options.i18n.firstParagraph }}</p>
    <ul class="gl-mb-0">
      <li>
        <gl-sprintf :message="$options.i18n.browseExamples">
          <template #link="{ content }">
            <gl-link
              :href="ciExamplesHelpPagePath"
              target="_blank"
              data-testid="ci-examples-link"
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
              data-testid="ci-yaml-link"
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
              data-testid="ci-help-link"
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
              data-testid="ci-needs-link"
              @click="trackHelpPageClick($options.CI_NEEDS_LINK)"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </li>
    </ul>
  </pipeline-editor-drawer-section>
</template>
