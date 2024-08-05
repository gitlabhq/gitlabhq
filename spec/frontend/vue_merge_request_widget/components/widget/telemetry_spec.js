import { mockTracking } from 'helpers/tracking_helper';
import { createTelemetryHub } from '~/vue_merge_request_widget/components/widget/telemetry';
import {
  VIEW_MERGE_REQUEST_WIDGET,
  EXPAND_MERGE_REQUEST_WIDGET,
  CLICK_FULL_REPORT_ON_MERGE_REQUEST_WIDGET,
} from '~/vue_merge_request_widget/constants';

describe('~/vue_merge_request_widget/components/widget/telemetry.js', () => {
  let trackingSpy;

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);
  });

  describe('component name manipulation', () => {
    it.each`
      widgetName             | standardized
      ${'WidgetNameThing'}   | ${'name_thing'}
      ${'WidgetName'}        | ${'name'}
      ${'WidgetNameThingCE'} | ${'name_thing'}
      ${'WidgetNameThingEE'} | ${'name_thing'}
    `(
      'properly converts widget name ($widgetName) to the standardized tracking format ($standardized)',
      ({ widgetName, standardized }) => {
        const hub = createTelemetryHub(widgetName);

        hub.viewed();

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          expect.any(String),
          expect.objectContaining({
            label: standardized,
          }),
        );
      },
    );
  });

  describe('event triggers', () => {
    const widgetName = 'WidgetNameThing';
    const standardized = 'name_thing';
    let hub;

    beforeEach(() => {
      hub = createTelemetryHub(widgetName);
    });

    it.each`
      method                 | eventName                                    | additionalPayload        | args
      ${'viewed'}            | ${VIEW_MERGE_REQUEST_WIDGET}                 | ${{}}                    | ${[]}
      ${'expanded'}          | ${EXPAND_MERGE_REQUEST_WIDGET}               | ${{ property: 'thing' }} | ${[{ type: 'thing' }]}
      ${'fullReportClicked'} | ${CLICK_FULL_REPORT_ON_MERGE_REQUEST_WIDGET} | ${{}}                    | ${[]}
    `(
      'sends the correct event ($eventName) and payload ($additionalPayload) to InternalEvents when .$method is called',
      ({ method, args, eventName, additionalPayload }) => {
        hub[method](...args);

        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          eventName,
          expect.objectContaining({
            label: standardized,
            ...additionalPayload,
          }),
        );
      },
    );
  });
});
