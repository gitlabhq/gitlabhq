/* global monaco */
import $ from 'jquery';
import Sidebar from './repo_sidebar';
import EditButton from './repo_edit_button';
import CommitSection from './repo_commit_section';
import Service from './repo_service';
import Store from './repo_store';
import Helper from './repo_helper';
import monacoLoader from './monaco_loader';

function initMonaco(el, cb) {
  monacoLoader(['vs/editor/editor.main'], () => {
    const monacoInstance = monaco.editor.create(el, {
      model: null,
      readOnly: true,
      contextmenu: false,
    });

    cb(monacoInstance);
  });
}

function initRepo() {
  const sidebar = document.getElementById('sidebar');
  const editButton = document.getElementById('editable-mode');
  const commitSection = document.getElementById('commit-area');

  Store.service = Service;
  Store.service.url = sidebar.dataset.url;

  Store.editButton = new EditButton(editButton);
  Store.commitSection = new CommitSection(commitSection);

  initMonaco(sidebar, (monacoInstance) => {
    Store.monacoInstance = monacoInstance;
    Store.sidebar = new Sidebar(sidebar);
    Helper.getContent();
  });
}

$(initRepo);

export default initRepo;
