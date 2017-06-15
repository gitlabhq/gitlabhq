/* global monaco */

window.require.config({ paths: { vs: '/monaco-editor/min/vs' } });
window.require(['vs/editor/editor.main'], () => {
  var editor = monaco.editor.create(document.getElementById('ide'), {
    value: "function hello() {\n\talert('Hello world!');\n}",
    language: 'javascript',
  });
});
