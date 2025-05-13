import { languages } from 'monaco-editor';
import { setDiagnosticsOptions as yamlDiagnosticsOptions } from 'monaco-yaml';

export function registerLanguages(def, ...defs) {
  defs.forEach((lang) => registerLanguages(lang));

  const languageId = def.id;

  languages.register(def);
  languages.setMonarchTokensProvider(languageId, def.language);
  languages.setLanguageConfiguration(languageId, def.conf);
}

export function registerSchema(schema, options = {}) {
  const defaultOptions = {
    validate: true,
    enableSchemaRequest: true,
    hover: true,
    completion: true,
    schemas: [schema],
    ...options,
  };
  languages.json.jsonDefaults.setDiagnosticsOptions(defaultOptions);
  yamlDiagnosticsOptions(defaultOptions);
}
