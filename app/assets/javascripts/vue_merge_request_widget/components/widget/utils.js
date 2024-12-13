const TEXT_STYLES = {
  success: {
    start: '%{success_start}',
    end: '%{success_end}',
  },
  danger: {
    start: '%{danger_start}',
    end: '%{danger_end}',
  },
  critical: {
    start: '%{critical_start}',
    end: '%{critical_end}',
  },
  same: {
    start: '%{same_start}',
    end: '%{same_end}',
  },
  strong: {
    start: '%{strong_start}',
    end: '%{strong_end}',
  },
  small: {
    start: '%{small_start}',
    end: '%{small_end}',
  },
};

const getStartTag = (tag) => TEXT_STYLES[tag].start;
const textStyleTags = {
  [getStartTag('success')]: '<span class="gl-font-bold gl-text-success">',
  [getStartTag('danger')]: '<span class="gl-font-bold gl-text-red-500">',
  [getStartTag('critical')]: '<span class="gl-font-bold gl-text-red-800">',
  [getStartTag('same')]: '<span class="gl-font-bold gl-text-gray-700">',
  [getStartTag('strong')]: '<span class="gl-font-bold">',
  [getStartTag('small')]: '<span class="gl-text-sm gl-text-gray-700">',
};

const escapeText = (text) =>
  document.createElement('div').appendChild(document.createTextNode(text)).parentNode.innerHTML;

const createText = (text) => {
  return text
    .replace(
      new RegExp(
        `(${Object.values(TEXT_STYLES)
          .reduce((acc, i) => [...acc, ...Object.values(i)], [])
          .join('|')})`,
        'gi',
      ),
      (replace) => {
        const replacement = textStyleTags[replace];

        // If the replacement tag ends with a `_end` then we can just return `</span>`
        // unless we have a replacement, for cases were we want to change the HTML tag
        if (!replacement && replace.endsWith('_end}')) {
          return '</span>';
        }

        return replacement;
      },
    )
    .replace(/%{([a-z]|_)+}/g, ''); // Filter out any tags we don't know about
};

export const generateText = (text) => {
  if (typeof text === 'string') {
    return createText(escapeText(text));
  }
  if (typeof text === 'object' && typeof text.text === 'string' && typeof text.href === 'string') {
    return createText(
      `${text.prependText ? `${escapeText(text.prependText)} ` : ''}<a class="gl-underline" href="${
        text.href
      }">${escapeText(text.text)}</a>`,
    );
  }

  return null;
};
