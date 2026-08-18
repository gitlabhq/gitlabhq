import fs from 'fs';
import yaml from 'js-yaml';
import { InternalEvents } from '~/tracking';

/**
 * Synchronously load and parse a YAML file.
 * Returns null if the file does not exist; throws for any other error.
 */
function loadYamlFileSync(path) {
  try {
    const fileData = fs.readFileSync(path, 'utf8');
    return yaml.safeLoad(fileData);
  } catch (err) {
    if (err.code === 'ENOENT') {
      return null;
    }
    throw new Error(`Error reading event definition file at ${path}: ${err.message}`);
  }
}

/**
 * Synchronously read and return the event definition for the given event name.
 *
 * Checks ee/config/events first for EE spec files, then falls back to
 * config/events. Throws synchronously when no definition file is found so
 * that the error is attributed to the test that triggered the missing event
 * rather than surfacing as an unhandled promise rejection in an unrelated suite.
 */
export function readEventDefinitionSync(eventName) {
  const isEE = expect.getState().testPath.includes('/ee/');
  const eePath = `./ee/config/events/${eventName}.yml`;
  const cePath = `./config/events/${eventName}.yml`;

  let eventDefinition;

  if (isEE) {
    eventDefinition = loadYamlFileSync(eePath) || loadYamlFileSync(cePath);
  } else {
    eventDefinition = loadYamlFileSync(cePath);
  }

  if (!eventDefinition) {
    throw new Error(
      `Missing event definition for "${eventName}". ` +
        `Create config/events/${eventName}.yml (or ee/config/events/${eventName}.yml for EE-only events). ` +
        `Run: bundle exec rails generate gitlab:internal_events:event_definition ${eventName}`,
    );
  }

  return eventDefinition;
}

export function useMockInternalEventsTracking() {
  let originalSnowplow;
  let trackEventSpy;
  let disposables = [];

  /**
   * Validate the event synchronously so that any error is thrown inside the
   * mock implementation and immediately fails the originating test rather than
   * becoming an unhandled promise rejection attributed to a different suite.
   */
  const validateEventSync = (eventName, properties) => {
    const eventDefinition = readEventDefinitionSync(eventName);

    if (eventDefinition.action !== eventName) {
      throw new Error(`Event "${eventName}" is not defined in event definitions.`);
    }

    const definedProperties = eventDefinition.additional_properties || {};
    Object.keys(properties).forEach((prop) => {
      if (!definedProperties[prop]) {
        throw new Error(
          `Property "${prop}" is not defined for event "${eventName}" in event definition file.`,
        );
      }
    });
  };

  const bindInternalEventDocument = (parent = document) => {
    const dispose = InternalEvents.bindInternalEventDocument(parent);
    disposables.push(dispose);

    const triggerEvent = (selectorOrEl, eventName = 'click') => {
      const event = new Event(eventName, { bubbles: true });
      const el =
        typeof selectorOrEl === 'string' ? parent.querySelector(selectorOrEl) : selectorOrEl;

      el.dispatchEvent(event);
    };

    return { triggerEvent, trackEventSpy };
  };

  beforeEach(() => {
    trackEventSpy = jest
      .spyOn(InternalEvents, 'trackEvent')
      .mockImplementation((eventName, properties = {}) => {
        validateEventSync(eventName, properties);
      });

    originalSnowplow = window.snowplow;
    window.snowplow = () => {};
  });

  afterEach(async () => {
    await Promise.all(disposables.map((dispose) => dispose && dispose()));
    disposables = [];
    window.snowplow = originalSnowplow;
  });

  return {
    bindInternalEventDocument,
  };
}
