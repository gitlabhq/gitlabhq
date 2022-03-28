<script>
import { s__ } from '~/locale';
import { ENVIRONMENTS_SCOPE } from '../constants';

export default {
  name: 'EnvironmentsEmptyState',
  props: {
    helpPath: {
      type: String,
      required: true,
    },
    scope: {
      type: String,
      required: true,
    },
  },
  computed: {
    title() {
      return this.$options.i18n.title[this.scope];
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
    link: s__('Environments|How do I create an environment?'),
  },
};
</script>
<template>
  <div class="empty-state">
    <div class="text-content">
      <h4 class="js-blank-state-title">
        {{ title }}
      </h4>
      <p>
        {{ $options.i18n.content }}
        <a :href="helpPath"> {{ $options.i18n.link }} </a>
      </p>
    </div>
  </div>
</template>
