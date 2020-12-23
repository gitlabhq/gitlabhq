function trimFirstCharOfLineContent(text) {
  if (!text) {
    return text;
  }

  return text.replace(/^( |\+|-)/, '');
}

function cleanSuggestionLine(line = {}) {
  return {
    ...line,
    text: trimFirstCharOfLineContent(line.text),
    rich_text: trimFirstCharOfLineContent(line.rich_text),
  };
}

export function selectDiffLines(lines) {
  return lines.filter((line) => line.type !== 'match').map((line) => cleanSuggestionLine(line));
}
