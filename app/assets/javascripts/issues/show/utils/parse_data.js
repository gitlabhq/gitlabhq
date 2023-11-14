import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { sanitize } from '~/lib/dompurify';

// We currently load + parse the data from the issue app and related merge request
let cachedParsedData;

export const parseIssuableData = (el) => {
  try {
    if (cachedParsedData) return cachedParsedData;

    const parsedData = JSON.parse(el.dataset.initial);
    parsedData.initialTitleHtml = sanitize(parsedData.initialTitleHtml);
    parsedData.initialDescriptionHtml = sanitize(parsedData.initialDescriptionHtml);

    cachedParsedData = parsedData;

    return parsedData;
  } catch (e) {
    Sentry.captureException(e);

    return {};
  }
};
