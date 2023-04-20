import * as Sentry from '@sentry/browser';
import getStandardContext from './get_standard_context';

export function dispatchSnowplowEvent(
  category = document.body.dataset.page,
  action = 'generic',
  data = {},
) {
  if (!category) {
    /* eslint-disable-next-line @gitlab/require-i18n-strings */
    throw new Error('Tracking: no category provided for tracking.');
  }

  const { label, property, extra = {} } = data;
  let { value } = data;

  const standardContext = getStandardContext({ extra });
  const contexts = [standardContext];

  if (data.context) {
    contexts.push(data.context);
  }

  if (value !== undefined) {
    value = Number(value);
  }

  try {
    window.snowplow('trackStructEvent', {
      category,
      action,
      label,
      property,
      value,
      context: contexts,
    });
    return true;
  } catch (error) {
    Sentry.captureException(error);
    return false;
  }
}
