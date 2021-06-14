<script>
import { GlButton, GlTabs, GlTab } from '@gitlab/ui';
import { INTEGRATION_TABS_CONFIG, I18N_INTEGRATION_TABS } from '../constants';
import PagerDutySettingsForm from './pagerduty_form.vue';

export default {
  components: {
    GlButton,
    GlTabs,
    GlTab,
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
  <section
    id="incident-management-settings"
    data-qa-selector="incidents_settings_content"
    class="settings no-animate"
  >
    <div class="settings-header">
      <h4
        ref="sectionHeader"
        class="settings-title js-settings-toggle js-settings-toggle-trigger-only"
      >
        {{ $options.i18n.headerText }}
      </h4>
      <gl-button ref="toggleBtn" class="js-settings-toggle">{{
        $options.i18n.expandBtnLabel
      }}</gl-button>
      <p ref="sectionSubHeader">
        {{ $options.i18n.subHeaderText }}
      </p>
    </div>

    <div class="settings-content">
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
    </div>
  </section>
</template>
