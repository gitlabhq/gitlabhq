<script>
import { GlButton, GlTable } from '@gitlab/ui';
import { s__ } from '~/locale';

const KEY_VISION_AI = 'key-vision-ai';
const KEY_NATURAL_LANGUAGE_AI = 'key-natural-language-ai';
const KEY_TRANSLATION_AI = 'key-translation-ai';

const i18n = {
  visionAi: s__('CloudSeed|Vision AI'),
  visionAiDescription: s__(
    'CloudSeed|Derive insights from your images in the cloud or at the edge',
  ),
  naturalLanguageAi: s__('CloudSeed|Language AI'),
  naturalLanguageAiDescription: s__(
    'CloudSeed|Derive insights from unstructured text using Google machine learning',
  ),
  translationAi: s__('CloudSeed|Translation AI'),
  translationAiDescription: s__(
    'CloudSeed|Make your content and apps multilingual with fast, dynamic machine translation',
  ),
  aiml: s__('CloudSeed|AI / ML'),
  aimlDescription: s__(
    "CloudSeed|Google Cloud's AI tools are armed with the best of Google's research and technology to help developers focus exclusively on solving problems that matter",
  ),
  configureViaMergeRequest: s__('CloudSeed|Configure via Merge Request'),
  service: s__('CloudSeed|Service'),
  description: s__('CloudSeed|Description'),
};

export default {
  components: { GlButton, GlTable },
  props: {
    visionAiUrl: {
      type: String,
      required: true,
    },
    languageAiUrl: {
      type: String,
      required: true,
    },
    translationAiUrl: {
      type: String,
      required: true,
    },
  },
  methods: {
    actionUrl(key) {
      switch (key) {
        case KEY_VISION_AI:
          return this.visionAiUrl;
        case KEY_NATURAL_LANGUAGE_AI:
          return this.languageAiUrl;
        case KEY_TRANSLATION_AI:
          return this.translationAiUrl;
        default:
          return '#';
      }
    },
  },
  fields: [
    { key: 'title', label: i18n.service },
    { key: 'description', label: i18n.description },
    { key: 'action', label: '' },
  ],
  items: [
    {
      title: i18n.naturalLanguageAi,
      description: i18n.naturalLanguageAiDescription,
      action: {
        key: KEY_NATURAL_LANGUAGE_AI,
        testId: 'button-natural-language-ai',
        title: i18n.configureViaMergeRequest,
      },
    },
    {
      title: i18n.translationAi,
      description: i18n.translationAiDescription,
      action: {
        key: KEY_TRANSLATION_AI,
        testId: 'button-translation-ai',
        title: i18n.configureViaMergeRequest,
        disabled: true,
      },
    },
    {
      title: i18n.visionAi,
      description: i18n.visionAiDescription,
      action: {
        key: KEY_VISION_AI,
        testId: 'button-vision-ai',
        title: i18n.configureViaMergeRequest,
      },
    },
  ],
  i18n,
};
</script>
<template>
  <div class="gl-mx-3">
    <h2 class="gl-text-size-h2">{{ $options.i18n.aiml }}</h2>
    <p>{{ $options.i18n.aimlDescription }}</p>
    <gl-table :fields="$options.fields" :items="$options.items">
      <template #cell(action)="{ value }">
        <gl-button
          :disabled="value.disabled"
          :href="actionUrl(value.key)"
          :data-testid="value.testId"
        >
          {{ value.title }}
        </gl-button>
      </template>
    </gl-table>
  </div>
</template>
