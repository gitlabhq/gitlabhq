import fuzzaldrinPlus from 'fuzzaldrin-plus';

export function getHighlightIndices(text, match, { global = false } = {}) {
  if (!text || !match) return new Set();

  if (global) {
    const indices = new Set();
    let pos = text.indexOf(match);
    while (pos !== -1) {
      for (let i = pos; i < pos + match.length; i += 1) {
        indices.add(i);
      }
      pos = text.indexOf(match, pos + match.length);
    }
    return indices;
  }

  return new Set(fuzzaldrinPlus.match(text, match));
}

export function buildSegments(text, indices) {
  if (!text) return [];
  if (!indices.size) return [{ text, highlight: false }];

  const result = [];

  for (let i = 0; i < text.length; i += 1) {
    const highlight = indices.has(i);
    const last = result[result.length - 1];

    if (last && last.highlight === highlight) {
      last.text += text[i];
    } else {
      result.push({ text: text[i], highlight });
    }
  }

  return result;
}
