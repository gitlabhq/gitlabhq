import $ from 'jquery';
import Tabs from './repo_tabs';
import Sidebar from './repo_sidebar';
import Editor from './repo_editor';
import FileButtons from './repo_file_buttons';
import EditButton from './repo_edit_button';
import BinaryViewer from './repo_binary_viewer';
import CommitSection from './repo_commit_section';
import Service from './repo_service';
import Store from './repo_store';
import Helper from './repo_helper';

function initRepo() {
  const ide = document.getElementById('ide');
  const tabs = document.getElementById('tabs');
  const sidebar = document.getElementById('sidebar');
  const fileButtons = document.getElementById('repo-file-buttons');
  const editButton = document.getElementById('editable-mode');
  const commitSection = document.getElementById('commit-area');
  const binaryViewer = document.getElementById('binary-viewer');

  const url = ide.dataset.url;

  Store.service = Service;
  Store.service.url = url;

  Store.tabs = new Tabs(tabs);
  Store.sidebar = new Sidebar(sidebar);
  Store.editor = new Editor(ide);
  Store.buttons = new FileButtons(fileButtons);
  Store.editButton = new EditButton(editButton);
  Store.commitSection = new CommitSection(commitSection);
  Store.binaryViewer = new BinaryViewer(binaryViewer);

  Helper.getContent();
}

$(initRepo);

export default initRepo;
