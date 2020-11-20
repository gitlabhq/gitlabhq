import * as Sentry from '~/sentry/wrapper';
import { sanitize } from '~/lib/dompurify';

// We currently load + parse the data from the issue app and related merge request
let cachedParsedData;

export const parseIssuableData = () => {
  try {
    if (cachedParsedData) return cachedParsedData;

    const initialDataEl = document.getElementById('js-issuable-app');

    const parsedData = JSON.parse(initialDataEl.dataset.initial);
    parsedData.initialTitleHtml = sanitize(parsedData.initialTitleHtml);
    parsedData.initialDescriptionHtml = sanitize(parsedData.initialDescriptionHtml);

    cachedParsedData = parsedData;

    return parsedData;
  } catch (e) {
    Sentry.captureException(e);

    return {};
  }
};
