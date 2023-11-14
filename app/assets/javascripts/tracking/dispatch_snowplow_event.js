import * as Sentry from '~/sentry/sentry_browser_wrapper';
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
  let contexts = [standardContext];

  if (data.context) {
    if (Array.isArray(data.context)) {
      contexts = [...contexts, ...data.context];
    } else {
      contexts.push(data.context);
    }
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
