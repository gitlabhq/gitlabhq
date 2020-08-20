const { languagesArr } = require('monaco-editor-webpack-plugin/out/languages');

// monaco-yaml library doesn't play so well with monaco-editor-webpack-plugin
// so the only way to include its workers is by patching the list of languages
// in monaco-editor-webpack-plugin and adding support for yaml workers. This is
// a known issue in the library and this workaround was suggested here:
// https://github.com/pengx17/monaco-yaml/issues/20

const yamlLang = languagesArr.find(t => t.label === 'yaml');

yamlLang.entry = [yamlLang.entry, '../../monaco-yaml/lib/esm/monaco.contribution'];
yamlLang.worker = {
  id: 'vs/language/yaml/yamlWorker',
  entry: '../../monaco-yaml/lib/esm/yaml.worker.js',
};

module.exports = require('monaco-editor-webpack-plugin');
