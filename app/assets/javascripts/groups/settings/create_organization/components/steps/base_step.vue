<script>
import { GlButton } from '@gitlab/ui';
import { Portal } from 'portal-vue';
import { __ } from '~/locale';
import { MODAL_FOOTER_PORTAL_NAME } from '../../constants';

export default {
  name: 'ReconciliationBaseStep',
  components: { GlButton, Portal },
  MODAL_FOOTER_PORTAL_NAME,
  props: {
    illustration: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    prevButtonText: {
      type: String,
      required: false,
      default: () => __('Back'),
    },
    nextButtonText: {
      type: String,
      required: false,
      default: () => __('Continue'),
    },
    nextButtonLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['next', 'prev'],
};
</script>

<template>
  <div>
    <div class="gl-mb-8 gl-text-center">
      <img v-if="illustration" :src="illustration" aria-hidden="true" class="gl-my-4 gl-max-w-20" />
      <h2 v-if="title" class="gl-heading-2">{{ title }}</h2>
      <div class="gl-mx-auto gl-w-full gl-max-w-md">
        <slot name="description"></slot>
      </div>
    </div>
    <slot></slot>
    <portal :to="$options.MODAL_FOOTER_PORTAL_NAME">
      <gl-button @click="$emit('prev')">{{ prevButtonText }}</gl-button>
      <gl-button variant="confirm" :loading="nextButtonLoading" @click="$emit('next')">{{
        nextButtonText
      }}</gl-button>
    </portal>
  </div>
</template>
