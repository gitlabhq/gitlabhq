import { InternalEvents } from '~/tracking';

import {
  VIEW_MERGE_REQUEST_WIDGET,
  EXPAND_MERGE_REQUEST_WIDGET,
  CLICK_FULL_REPORT_ON_MERGE_REQUEST_WIDGET,
} from '../../constants';

function simplifyWidgetName(componentName) {
  const noWidget = componentName.replace(/^Widget/, '');
  const camelName = noWidget.charAt(0).toLowerCase() + noWidget.slice(1);
  const tierlessName = camelName.replace(/(CE|EE)$/, '');

  return tierlessName;
}

function baseWidgetName(extensionName) {
  return extensionName.replace(/([A-Z])/g, '_$1').toLowerCase();
}

export function createTelemetryHub(componentName) {
  return {
    viewed() {
      InternalEvents.trackEvent(VIEW_MERGE_REQUEST_WIDGET, {
        label: baseWidgetName(simplifyWidgetName(componentName)),
      });
    },
    expanded({ type }) {
      InternalEvents.trackEvent(EXPAND_MERGE_REQUEST_WIDGET, {
        label: baseWidgetName(simplifyWidgetName(componentName)),
      });

      InternalEvents.trackEvent(EXPAND_MERGE_REQUEST_WIDGET, {
        label: baseWidgetName(simplifyWidgetName(componentName)),
        property: type,
      });
    },
    fullReportClicked() {
      InternalEvents.trackEvent(CLICK_FULL_REPORT_ON_MERGE_REQUEST_WIDGET, {
        label: baseWidgetName(simplifyWidgetName(componentName)),
      });
    },
  };
}
