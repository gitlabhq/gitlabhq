import fs from 'fs/promises';
import yaml from 'js-yaml';
import { InternalEvents } from '~/tracking';

async function loadYamlFile(path) {
  try {
    const fileData = await fs.readFile(path, 'utf8');
    return yaml.safeLoad(fileData);
  } catch (err) {
    if (err.code === 'ENOENT') {
      return null;
    }
    throw new Error(`Error reading event definition file at ${path}: ${err.message}`);
  }
}

export async function readEventDefinition(eventName) {
  const isEE = expect.getState().testPath.includes('/ee/');
  const eePath = `./ee/config/events/${eventName}.yml`;
  const cePath = `./config/events/${eventName}.yml`;

  let eventDefinition;

  if (isEE) {
    eventDefinition = (await loadYamlFile(eePath)) || (await loadYamlFile(cePath));
  } else {
    eventDefinition = await loadYamlFile(cePath);
  }

  if (!eventDefinition) {
    throw new Error(`Event definition file not found for ${eventName}`);
  }

  return eventDefinition;
}

export function useMockInternalEventsTracking() {
  let originalSnowplow;
  let trackEventSpy;
  let disposables = [];
  let eventDefinition;

  const validateEvent = async (eventName, properties) => {
    eventDefinition = await readEventDefinition(eventName);
    if (eventDefinition.action !== eventName) {
      throw new Error(`Event "${eventName}" is not defined in event definitions.`);
    }

    const definedProperties = eventDefinition.additional_properties || {};
    Object.keys(properties).forEach((prop) => {
      if (!definedProperties[prop]) {
        throw new Error(
          `Property "${prop}" is not defined for event "${eventName} in event definition file".`,
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
      .mockImplementation(async (eventName, properties = {}) => {
        await validateEvent(eventName, properties);
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
