<!-- eslint-disable vue/multi-word-component-names -->
<script>
import GoogleCloudMenu from '../components/google_cloud_menu.vue';
import IncubationBanner from '../components/incubation_banner.vue';
import ServiceTable from './service_table.vue';

export default {
  components: {
    IncubationBanner,
    GoogleCloudMenu,
    ServiceTable,
  },
  props: {
    configurationUrl: {
      type: String,
      required: true,
    },
    deploymentsUrl: {
      type: String,
      required: true,
    },
    databasesUrl: {
      type: String,
      required: true,
    },
    aimlUrl: {
      type: String,
      required: true,
    },
    visionAiUrl: {
      type: String,
      required: true,
    },
    translationAiUrl: {
      type: String,
      required: true,
    },
    languageAiUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <incubation-banner />

    <google-cloud-menu
      active="aiml"
      :configuration-url="configurationUrl"
      :deployments-url="deploymentsUrl"
      :databases-url="databasesUrl"
      :aiml-url="aimlUrl"
    />

    <service-table
      :language-ai-url="languageAiUrl"
      :translation-ai-url="translationAiUrl"
      :vision-ai-url="visionAiUrl"
    />
  </div>
</template>
