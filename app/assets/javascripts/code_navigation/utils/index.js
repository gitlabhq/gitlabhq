export const cachedData = new Map();

export const getCurrentHoverElement = () => cachedData.get('current');
export const setCurrentHoverElement = el => cachedData.set('current', el);

export const addInteractionClass = (path, d) => {
  const lineNumber = d.start_line + 1;
  const lines = document
    .querySelector(`[data-path="${path}"]`)
    .querySelectorAll(`.blob-content #LC${lineNumber}, .line_content:not(.old) #LC${lineNumber}`);
  if (!lines?.length) return;

  lines.forEach(line => {
    let charCount = 0;
    const el = [...line.childNodes].find(({ textContent }) => {
      if (charCount === d.start_char) return true;
      charCount += textContent.length;
      return false;
    });

    if (el) {
      el.setAttribute('data-char-index', d.start_char);
      el.setAttribute('data-line-index', d.start_line);
      el.classList.add('cursor-pointer', 'code-navigation', 'js-code-navigation');
      el.closest('.line').classList.add('code-navigation-line');
    }
  });
};
