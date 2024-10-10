<script>
import { GlButton, GlTabs, GlTab } from '@gitlab/ui';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import { INTEGRATION_TABS_CONFIG, I18N_INTEGRATION_TABS } from '../constants';
import PagerDutySettingsForm from './pagerduty_form.vue';

export default {
  components: {
    GlButton,
    GlTabs,
    GlTab,
    SettingsBlock,
    PagerDutySettingsForm,
    ServiceLevelAgreementForm: () =>
      import('ee_component/incidents_settings/components/service_level_agreement_form.vue'),
  },
  computed: {
    activeTabs() {
      return this.$options.tabs.filter((tab) => tab.active);
    },
  },
  tabs: INTEGRATION_TABS_CONFIG,
  i18n: I18N_INTEGRATION_TABS,
};
</script>

<template>
  <settings-block
    id="incident-management-settings"
    :title="$options.i18n.headerText"
    data-testid="incidents-settings-content"
  >
    <template #description>
      <span ref="sectionSubHeader">{{ $options.i18n.subHeaderText }}</span>
    </template>

    <template #default>
      <gl-tabs>
        <service-level-agreement-form />
        <gl-tab
          v-for="(tab, index) in activeTabs"
          :key="`${tab.title}_${index}`"
          :title="tab.title"
        >
          <component :is="tab.component" class="gl-pt-3" :data-testid="`${tab.component}-tab`" />
        </gl-tab>
      </gl-tabs>
    </template>
  </settings-block>
</template>
