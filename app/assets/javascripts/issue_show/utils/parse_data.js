import { sanitize } from 'dompurify';

export const parseIssuableData = () => {
  try {
    const initialDataEl = document.getElementById('js-issuable-app-initial-data');

    const parsedData = JSON.parse(initialDataEl.textContent.replace(/&quot;/g, '"'));

    parsedData.initialTitleHtml = sanitize(parsedData.initialTitleHtml);
    parsedData.initialDescriptionHtml = sanitize(parsedData.initialDescriptionHtml);

    return parsedData;
  } catch (e) {
    console.error(e); // eslint-disable-line no-console

    return {};
  }
};

export default {};
