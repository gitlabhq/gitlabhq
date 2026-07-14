import Vue from 'vue';
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

  return new Vue({
    el,
    name: 'LoggingFieldSettingsRoot',
    render(createElement) {
      return createElement(LoggingFieldSettings, {
        props: {
          persistedVersion: parseInt(persistedVersion, 10),
          persistedDualEmitTarget:
            persistedDualEmitTarget === '' || persistedDualEmitTarget == null
              ? null
              : parseInt(persistedDualEmitTarget, 10),
          latestVersion: parseInt(latestVersion, 10),
          availableVersions: JSON.parse(availableVersions),
          fieldChanges: JSON.parse(fieldChanges || '{}'),
        },
      });
    },
  });
};
