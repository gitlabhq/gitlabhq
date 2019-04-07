import sanitize from 'sanitize-html';

export const parseIssuableData = () => {
  try {
    const initialDataEl = document.getElementById('js-issuable-app-initial-data');

    return JSON.parse(sanitize(initialDataEl.textContent).replace(/&quot;/g, '"'));
  } catch (e) {
    console.error(e); // eslint-disable-line no-console

    return {};
  }
};

export default {};
