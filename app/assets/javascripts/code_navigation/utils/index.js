export const cachedData = new Map();

export const getCurrentHoverElement = () => cachedData.get('current');
export const setCurrentHoverElement = el => cachedData.set('current', el);

export const addInteractionClass = d => {
  let charCount = 0;
  const line = document.getElementById(`LC${d.start_line + 1}`);
  const el = [...line.childNodes].find(({ textContent }) => {
    if (charCount === d.start_char) return true;
    charCount += textContent.length;
    return false;
  });

  if (el) {
    el.setAttribute('data-char-index', d.start_char);
    el.setAttribute('data-line-index', d.start_line);
    el.classList.add('cursor-pointer', 'code-navigation', 'js-code-navigation');
  }
};
