function removeEmptyProperties(dict) {
  const noBlanks = Object.entries(dict).reduce((final, [key, value]) => {
    const upd = { ...final };

    // The number 0 shouldn't be falsey when we're printing variables
    if (value || value === 0) {
      upd[key] = value;
    }

    return upd;
  }, {});

  return noBlanks;
}

export function computeSuggestionCommitMessage({ message, values = {} } = {}) {
  const noEmpties = removeEmptyProperties(values);
  const matchPhrases = Object.keys(noEmpties)
    .map((key) => `%{${key}}`)
    .join('|');
  const replacementExpression = new RegExp(`(${matchPhrases})`, 'gm');

  return message.replace(replacementExpression, (match) => {
    const key = match.replace(/(^%{|}$)/gm, '');

    return noEmpties[key];
  });
}
