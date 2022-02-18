<script>
import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { mapState } from 'vuex';
import { s__ } from '~/locale';
import { DEPRECATION_POST_LINK } from '../constants';

export default {
  components: {
    GlEmptyState,
    GlLink,
    GlSprintf,
  },
  i18n: {
    title: s__('Serverless|Getting started with serverless'),
    description: s__(
      'Serverless|Serverless was %{postLinkStart}deprecated%{postLinkEnd}. But if you opt to use it, you must install Knative in your Kubernetes cluster first. %{linkStart}Learn more.%{linkEnd}',
    ),
  },
  deprecationPostLink: DEPRECATION_POST_LINK,
  computed: {
    ...mapState(['emptyImagePath', 'helpPath']),
  },
};
</script>

<template>
  <gl-empty-state :svg-path="emptyImagePath" :title="$options.i18n.title">
    <template #description>
      <gl-sprintf :message="$options.i18n.description">
        <template #postLink="{ content }">
          <gl-link :href="$options.deprecationPostLink" target="_blank">{{ content }}</gl-link>
        </template>
        <template #link="{ content }">
          <gl-link :href="helpPath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </template>
  </gl-empty-state>
</template>
