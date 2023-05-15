<script>
import { s__ } from '~/locale';

const CONFIGURATION_KEY = 'configuration';
const DEPLOYMENTS_KEY = 'deployments';
const DATABASES_KEY = 'databases';
const AIML_KEY = 'aiml';

const i18n = {
  configuration: { title: s__('CloudSeed|Configuration') },
  deployments: { title: s__('CloudSeed|Deployments') },
  databases: { title: s__('CloudSeed|Databases') },
  aiml: { title: s__('CloudSeed|AI / ML') },
};

export default {
  props: {
    active: {
      type: String,
      required: true,
    },
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
      required: false,
      default: '',
    },
  },
  computed: {
    isConfigurationActive() {
      return this.active === CONFIGURATION_KEY;
    },
    isDeploymentsActive() {
      return this.active === DEPLOYMENTS_KEY;
    },
    isDatabasesActive() {
      return this.active === DATABASES_KEY;
    },
    isAimlActive() {
      return this.active === AIML_KEY;
    },
  },
  i18n,
};
</script>
<template>
  <div class="tabs gl-tabs">
    <ul role="tablist" class="nav gl-tabs-nav">
      <li role="presentation" class="nav-item">
        <a
          data-testid="configurationLink"
          role="tab"
          :href="configurationUrl"
          class="nav-link gl-tab-nav-item"
          :class="{ 'gl-tab-nav-item-active': isConfigurationActive }"
        >
          {{ $options.i18n.configuration.title }}</a
        >
      </li>
      <li role="presentation" class="nav-item">
        <a
          data-testid="deploymentsLink"
          role="tab"
          :href="deploymentsUrl"
          class="nav-link gl-tab-nav-item"
          :class="{ 'gl-tab-nav-item-active': isDeploymentsActive }"
        >
          {{ $options.i18n.deployments.title }}
        </a>
      </li>
      <li role="presentation" class="nav-item">
        <a
          data-testid="databasesLink"
          role="tab"
          :href="databasesUrl"
          class="nav-link gl-tab-nav-item"
          :class="{ 'gl-tab-nav-item-active': isDatabasesActive }"
        >
          {{ $options.i18n.databases.title }}
        </a>
      </li>
      <li role="presentation" class="nav-item">
        <a
          data-testid="aimlLink"
          role="tab"
          :href="aimlUrl"
          class="nav-link gl-tab-nav-item hidden"
          :class="{ 'gl-tab-nav-item-active': isAimlActive }"
        >
          {{ $options.i18n.aiml.title }}
        </a>
      </li>
    </ul>
  </div>
</template>
