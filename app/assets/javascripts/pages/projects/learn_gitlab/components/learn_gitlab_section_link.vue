<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ACTION_LABELS } from '../constants';

export default {
  name: 'LearnGitlabSectionLink',
  components: { GlLink, GlIcon },
  i18n: {
    ACTION_LABELS,
    trialOnly: s__('LearnGitlab|Trial only'),
  },
  props: {
    action: {
      required: true,
      type: String,
    },
    value: {
      required: true,
      type: Object,
    },
  },
  computed: {
    trialOnly() {
      return ACTION_LABELS[this.action].trialRequired;
    },
  },
};
</script>
<template>
  <div class="gl-mb-4">
    <span v-if="value.completed" class="gl-text-green-500">
      <gl-icon name="check-circle-filled" :size="16" data-testid="completed-icon" />
      {{ $options.i18n.ACTION_LABELS[action].title }}
    </span>
    <span v-else>
      <gl-link
        target="_blank"
        :href="value.url"
        data-track-action="click_link"
        :data-track-label="$options.i18n.ACTION_LABELS[action].title"
        data-track-property="Growth::Conversion::Experiment::LearnGitLabA"
      >
        {{ $options.i18n.ACTION_LABELS[action].title }}
      </gl-link>
    </span>
    <span v-if="trialOnly" class="gl-font-style-italic gl-text-gray-500" data-testid="trial-only">
      - {{ $options.i18n.trialOnly }}
    </span>
  </div>
</template>
