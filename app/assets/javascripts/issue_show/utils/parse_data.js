import { sanitize } from '~/lib/dompurify';

// We currently load + parse the data from the issue app and related merge request
let cachedParsedData;

export const parseIssuableData = () => {
  try {
    if (cachedParsedData) return cachedParsedData;

    const initialDataEl = document.getElementById('js-issuable-app-initial-data');

    const parsedData = JSON.parse(initialDataEl.textContent.replace(/&quot;/g, '"'));

    parsedData.initialTitleHtml = sanitize(parsedData.initialTitleHtml);
    parsedData.initialDescriptionHtml = sanitize(parsedData.initialDescriptionHtml);

    cachedParsedData = parsedData;

    return parsedData;
  } catch (e) {
    console.error(e); // eslint-disable-line no-console

    return {};
  }
};

export default {};
