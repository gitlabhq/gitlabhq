<script>
import { GlButton, GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  name: 'SatisfactionRate',
  components: {
    GlButton,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    unhappy: s__('Surveys|Unhappy'),
    delighted: s__('Surveys|Delighted'),
  },
  grades: [
    {
      title: s__('Surveys|Unhappy'),
      icon: 'face-unhappy',
      value: 1,
    },
    {
      title: s__('Surveys|Sad'),
      icon: 'slight-frown',
      value: 2,
    },
    {
      title: s__('Surveys|Neutral'),
      icon: 'face-neutral',
      value: 3,
    },
    {
      title: s__('Surveys|Happy'),
      icon: 'slight-smile',
      value: 4,
    },
    {
      title: s__('Surveys|Delighted'),
      icon: 'smiley',
      value: 5,
    },
  ],
};
</script>

<template>
  <div>
    <ul class="gl-m-0 gl-flex gl-list-none gl-justify-between gl-p-0">
      <li v-for="grade in $options.grades" :key="grade.value">
        <gl-button
          v-gl-tooltip="grade.title"
          class="!gl-p-2"
          variant="default"
          category="tertiary"
          :aria-label="grade.title"
          @click="$emit('rate', grade.value)"
        >
          <gl-icon class="gl-align-top" :name="grade.icon" :size="24" />
        </gl-button>
      </li>
    </ul>
    <div class="gl-flex gl-justify-between gl-pt-3 gl-text-sm gl-text-subtle">
      <div>{{ $options.i18n.unhappy }}</div>
      <div>{{ $options.i18n.delighted }}</div>
    </div>
  </div>
</template>
