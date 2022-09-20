<script>
import { GlEmptyState, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { ENVIRONMENTS_SCOPE } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlLink,
  },
  inject: ['newEnvironmentPath'],
  props: {
    helpPath: {
      type: String,
      required: true,
    },
    scope: {
      type: String,
      required: true,
    },
    hasTerm: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    title() {
      return this.hasTerm
        ? this.$options.i18n.searchingTitle
        : this.$options.i18n.title[this.scope];
    },
    content() {
      return this.hasTerm ? this.$options.i18n.searchingContent : this.$options.i18n.content;
    },
    buttonText() {
      return this.hasTerm ? this.$options.i18n.newEnvironmentButtonLabel : '';
    },
  },
  i18n: {
    title: {
      [ENVIRONMENTS_SCOPE.AVAILABLE]: s__("Environments|You don't have any environments."),
      [ENVIRONMENTS_SCOPE.STOPPED]: s__("Environments|You don't have any stopped environments."),
    },
    content: s__(
      'Environments|Environments are places where code gets deployed, such as staging or production.',
    ),
    searchingTitle: s__('Environments|No results found'),
    searchingContent: s__('Environments|Edit your search and try again'),
    link: s__('Environments|How do I create an environment?'),
    newEnvironmentButtonLabel: s__('Environments|New environment'),
  },
};
</script>
<template>
  <gl-empty-state :primary-button-text="buttonText" :primary-button-link="newEnvironmentPath">
    <template #title>
      <h4>{{ title }}</h4>
    </template>
    <template #description>
      <p>{{ content }}</p>
      <gl-link v-if="!hasTerm" :href="helpPath">{{ $options.i18n.link }}</gl-link>
    </template>
  </gl-empty-state>
</template>
