<script>
import { GlButton, GlPopover, GlSprintf, GlOutsideDirective as Outside } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  directives: { Outside },
  i18n: {
    title: s__('pipelineEditorWalkthrough|See how GitLab pipelines work'),
    description: s__(
      'pipelineEditorWalkthrough|This %{codeStart}.gitlab-ci.yml%{codeEnd} file creates a simple test pipeline.',
    ),
    instruction: s__(
      'pipelineEditorWalkthrough|Use the %{boldStart}commit changes%{boldEnd} button at the bottom of the page to run the pipeline.',
    ),
    ctaText: s__("pipelineEditorWalkthrough|Let's do this!"),
  },
  components: {
    GlButton,
    GlPopover,
    GlSprintf,
  },
  data() {
    return {
      show: true,
    };
  },
  computed: {
    targetElement() {
      return document.querySelector('.js-walkthrough-popover-target');
    },
  },
  methods: {
    close() {
      this.show = false;
    },
    handleClickCta() {
      this.close();
      this.$emit('walkthrough-popover-cta-clicked');
    },
  },
};
</script>

<template>
  <gl-popover
    :show.sync="show"
    :title="$options.i18n.title"
    :target="targetElement"
    placement="right"
    triggers="focus"
  >
    <div v-outside="close" class="gl-flex gl-flex-col">
      <p>
        <gl-sprintf :message="$options.i18n.description">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>

      <p>
        <gl-sprintf :message="$options.i18n.instruction">
          <template #bold="{ content }">
            <strong>
              {{ content }}
            </strong>
          </template>
        </gl-sprintf>
      </p>

      <gl-button
        class="gl-self-end"
        category="tertiary"
        data-testid="ctaBtn"
        variant="confirm"
        @click="handleClickCta"
      >
        <gl-emoji data-name="rocket" />
        {{ $options.i18n.ctaText }}
      </gl-button>
    </div>
  </gl-popover>
</template>
