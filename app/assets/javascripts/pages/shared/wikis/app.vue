<script>
import { GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';
import WikiHeader from './components/wiki_header.vue';
import WikiContent from './components/wiki_content.vue';

export default {
  components: {
    GlAlert,
    WikiHeader,
    WikiContent,
  },
  inject: ['contentApi', 'isPageHistorical', 'wikiUrl', 'historyUrl'],
  i18n: {
    alertText: s__('WikiHistoricalPage|This is an old version of this page.'),
    alertPrimaryButton: s__('WikiHistoricalPage|Go to most recent version'),
    alertSecondaryButton: s__('WikiHistoricalPage|Browse history'),
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="isPageHistorical"
      :dismissible="false"
      variant="warning"
      class="gl-mt-5"
      :primary-button-text="$options.i18n.alertPrimaryButton"
      :primary-button-link="wikiUrl"
      :secondary-button-text="$options.i18n.alertSecondaryButton"
      :secondary-button-link="historyUrl"
    >
      {{ $options.i18n.alertText }}
    </gl-alert>
    <wiki-header />
    <wiki-content v-if="contentApi" :get-wiki-content-url="contentApi" />
  </div>
</template>
