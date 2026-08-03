import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { parseRailsFormFields } from '~/lib/utils/forms';
import LoggingFieldSettings from './components/logging_field_settings.vue';

export const initLoggingFieldSettings = () => {
  const el = document.querySelector('#js-logging-field-settings');

  if (!el) {
    return false;
  }

  const {
    persistedVersion,
    persistedDualEmitTarget,
    latestVersion,
    availableVersions,
    fieldChanges,
  } = el.dataset;

  const { schemaVersion, dualEmitTarget } = parseRailsFormFields(el);

  return initVueApp({
    el,
    name: 'LoggingFieldSettingsRoot',
    component: LoggingFieldSettings,
    props: {
      persistedVersion: parseInt(persistedVersion, 10),
      persistedDualEmitTarget:
        persistedDualEmitTarget === '' || persistedDualEmitTarget == null
          ? null
          : parseInt(persistedDualEmitTarget, 10),
      latestVersion: parseInt(latestVersion, 10),
      availableVersions: JSON.parse(availableVersions),
      fieldChanges: JSON.parse(fieldChanges || '{}'),
      schemaFieldName: schemaVersion.name,
      dualEmitFieldName: dualEmitTarget.name,
    },
  });
};
