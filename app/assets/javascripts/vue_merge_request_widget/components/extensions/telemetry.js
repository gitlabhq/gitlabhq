import api from '~/api';
import createEventHub from '~/helpers/event_hub_factory';
import {
  TELEMETRY_WIDGET_VIEWED,
  TELEMETRY_WIDGET_EXPANDED,
  TELEMETRY_WIDGET_FULL_REPORT_CLICKED,
} from '../../constants';

function simplifyWidgetName(componentName) {
  const noWidget = componentName.replace(/^Widget/, '');
  const camelName = noWidget.charAt(0).toLowerCase() + noWidget.slice(1);
  const tierlessName = camelName.replace(/(CE|EE)$/, '');

  return tierlessName;
}

function baseRedisEventName(extensionName) {
  const redisEventName = extensionName.replace(/([A-Z])/g, '_$1').toLowerCase();

  return `i_code_review_merge_request_widget_${redisEventName}`;
}

function whenable(bus) {
  return function when(event) {
    return ({ execute, track, special }) => {
      bus.$on(event, (busEvent) => {
        track.forEach((redisEvent) => {
          execute(redisEvent);
        });

        special?.({ event, execute, track, bus, busEvent });
      });
    };
  };
}

function defaultBehaviorEvents({ bus, config }) {
  const when = whenable(bus);
  const isViewed = when(TELEMETRY_WIDGET_VIEWED);
  const isExpanded = when(TELEMETRY_WIDGET_EXPANDED);
  const fullReportIsClicked = when(TELEMETRY_WIDGET_FULL_REPORT_CLICKED);
  const toHll = config?.uniqueUser || {};
  const toCounts = config?.counter || {};
  const user = api.trackRedisHllUserEvent.bind(api);
  const count = api.trackRedisCounterEvent.bind(api);

  if (toHll.view) {
    isViewed({ execute: user, track: toHll.view });
  }
  if (toCounts.view) {
    isViewed({ execute: count, track: toCounts.view });
  }

  if (toHll.expand) {
    isExpanded({
      execute: user,
      track: toHll.expand,
      special: ({ execute, track, busEvent }) => {
        if (busEvent.type) {
          track.forEach((event) => {
            execute(`${event}_${busEvent.type}`);
          });
        }
      },
    });
  }
  if (toCounts.expand) {
    isExpanded({
      execute: count,
      track: toCounts.expand,
      special: ({ execute, track, busEvent }) => {
        if (busEvent.type) {
          track.forEach((event) => {
            execute(`${event}_${busEvent.type}`);
          });
        }
      },
    });
  }

  if (toHll.clickFullReport) {
    fullReportIsClicked({ execute: user, track: toHll.clickFullReport });
  }
  if (toCounts.clickFullReport) {
    fullReportIsClicked({ execute: count, track: toCounts.clickFullReport });
  }
}

function baseTelemetry(componentName) {
  const simpleExtensionName = simplifyWidgetName(componentName);
  /*
   * Telemetry config format is:
   *    {
   *        TELEMETRY_TYPE: {
   *            BEHAVIOR: [ EVENT_NAME, ... ]
   *        }
   *    }
   *
   * Right now, there are currently configurations for these telemetry types:
   *     - uniqueUser is sent to RedisHLL
   *     - counter is sent to a regular Redis counter
   */
  return {
    uniqueUser: {
      view: [`${baseRedisEventName(simpleExtensionName)}_view`],
      expand: [`${baseRedisEventName(simpleExtensionName)}_expand`],
      clickFullReport: [`${baseRedisEventName(simpleExtensionName)}_click_full_report`],
    },
    counter: {
      view: [`${baseRedisEventName(simpleExtensionName)}_count_view`],
      expand: [`${baseRedisEventName(simpleExtensionName)}_count_expand`],
      clickFullReport: [`${baseRedisEventName(simpleExtensionName)}_count_click_full_report`],
    },
  };
}

export function createTelemetryHub(componentName) {
  const bus = createEventHub();
  const config = baseTelemetry(componentName);

  defaultBehaviorEvents({ bus, config });

  return {
    viewed() {
      bus.$emit(TELEMETRY_WIDGET_VIEWED);
    },
    expanded({ type }) {
      bus.$emit(TELEMETRY_WIDGET_EXPANDED, { type });
    },
    fullReportClicked() {
      bus.$emit(TELEMETRY_WIDGET_FULL_REPORT_CLICKED);
    },
    /* I want a Record here: #{ ...config } // and then the comment would be: This is for debugging only, changing your reference to it does nothing. 😘 */
    config: Object.freeze({ ...config }), // This is *intended* to be for debugging only, but it's pretty mutable, and it has references to live data in child props
    bus,
  };
}
