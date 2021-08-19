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

  const { label, property, value, extra = {} } = data;

  const standardContext = getStandardContext({ extra });
  const contexts = [standardContext];

  if (data.context) {
    contexts.push(data.context);
  }

  return window.snowplow('trackStructEvent', category, action, label, property, value, contexts);
}
