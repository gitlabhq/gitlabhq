import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { dispatchSnowplowEvent } from '~/tracking/dispatch_snowplow_event';
import getStandardContext from '~/tracking/get_standard_context';
import { isEventEligible } from '~/tracking/utils';
import { extraContext, servicePingContext } from './mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/tracking/get_standard_context');
jest.mock('~/tracking/utils', () => ({
  ...jest.requireActual('~/tracking/utils'),
  isEventEligible: jest.fn(),
  validateEvent: jest.fn(),
}));

const category = 'Incident Management';
const action = 'view_incident_details';

describe('dispatchSnowplowEvent', () => {
  const snowplowMock = jest.fn();
  global.window.snowplow = snowplowMock;

  const mockStandardContext = { some: 'context' };
  getStandardContext.mockReturnValue(mockStandardContext);

  beforeEach(() => {
    snowplowMock.mockClear();
    Sentry.captureException.mockClear();
    isEventEligible.mockReturnValue(true);
  });

  it('calls snowplow trackStructEvent with correct arguments', () => {
    const data = {
      label: 'Show Incident',
      property: 'click_event',
      value: '12',
      context: extraContext,
      extra: { namespace: 'GitLab' },
    };

    dispatchSnowplowEvent(category, action, data);

    expect(snowplowMock).toHaveBeenCalledWith('trackStructEvent', {
      category,
      action,
      label: data.label,
      property: data.property,
      value: Number(data.value),
      context: [mockStandardContext, data.context],
    });
  });

  it('throws an error if no category is provided', () => {
    expect(() => {
      dispatchSnowplowEvent(undefined, 'some-action', {});
    }).toThrow('Tracking: no category provided for tracking.');
  });

  it('handles an array of contexts', () => {
    const data = {
      context: [extraContext, servicePingContext],
      extra: { namespace: 'GitLab' },
    };

    dispatchSnowplowEvent(category, action, data);

    expect(snowplowMock).toHaveBeenCalledWith('trackStructEvent', {
      category,
      action,
      context: [mockStandardContext, ...data.context],
    });
  });

  it('handles Sentry error capturing', () => {
    snowplowMock.mockImplementation(() => {
      throw new Error('some error');
    });

    dispatchSnowplowEvent(category, action, {});

    expect(Sentry.captureException).toHaveBeenCalledTimes(1);
  });

  it('returns false when event is not eligible', () => {
    isEventEligible.mockReturnValue(false);

    const result = dispatchSnowplowEvent(category, action, {});

    expect(result).toBe(false);
    expect(snowplowMock).not.toHaveBeenCalled();
  });

  it('returns true and tracks event when event is eligible', () => {
    isEventEligible.mockReturnValue(true);

    snowplowMock.mockImplementation(() => {});

    const result = dispatchSnowplowEvent(category, action, {});

    expect(result).toBe(true);
    expect(snowplowMock).toHaveBeenCalledTimes(1);
  });
});
