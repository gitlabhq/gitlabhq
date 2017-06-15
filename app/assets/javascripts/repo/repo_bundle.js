import monaco from 'monaco-editor'

monaco.editor.create(document.getElementById("ide"), {
	value: "function hello() {\n\talert('Hello world!');\n}",
	language: "javascript"
});