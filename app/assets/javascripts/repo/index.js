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

$(() => {
  const url = document.getElementById('ide').dataset.url;
  Store.service = Service;
  Store.service.url = url;
  Store.tabs = new Tabs();
  Store.sidebar = new Sidebar(url);
  Store.editor = new Editor();
  Store.buttons = new FileButtons();
  Store.editButton = new EditButton();
  Store.commitSection = new CommitSection();
  Store.binaryViewer = new BinaryViewer();
  Helper.getContent();
});
