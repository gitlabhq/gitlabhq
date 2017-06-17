/* global monaco */
import Sidebar from './repo_sidebar'
import Service from './repo_service'

class RepoBundle {
  constructor(id, url) {
    this.service = Service;
    this.service.url = url;
    this.sidebar = new Sidebar(url);
  }
}

window.require.config({ paths: { vs: '/monaco-editor/min/vs' } });
window.require(['vs/editor/editor.main'], () => {
  var editor = monaco.editor.create(document.getElementById('ide'), {
    value: "function hello() {\n\talert('Hello world!');\n}",
    language: 'javascript',
  });
});
document.addEventListener('DOMContentLoaded', ()=> {
  const ideRoot = document.getElementById('ide');
  const bundle = new RepoBundle(
    ideRoot,
    ideRoot.dataset.url
  );
});
