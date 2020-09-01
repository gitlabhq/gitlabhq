const frontMatterLanguageDefinitions = [
  { name: 'yaml', open: '---', close: '---' },
  { name: 'toml', open: '\\+\\+\\+', close: '\\+\\+\\+' },
  { name: 'json', open: '{', close: '}' },
];

const getFrontMatterLanguageDefinition = name => {
  const languageDefinition = frontMatterLanguageDefinitions.find(def => def.name === name);

  if (!languageDefinition) {
    throw new Error(`Unsupported front matter language: ${name}`);
  }

  return languageDefinition;
};

export default getFrontMatterLanguageDefinition;
