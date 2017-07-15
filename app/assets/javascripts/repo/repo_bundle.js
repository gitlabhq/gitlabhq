import Tabs from './repo_tabs';
import Sidebar from './repo_sidebar';
import Editor from './repo_editor';
import FileButtons from './repo_file_buttons';
import BinaryViewer from './repo_binary_viewer';
import Service from './repo_service';
import Store from './repo_store';
import Helper from './repo_helper';

export default class RepoBundle {
  constructor() {
    const url = document.getElementById('ide').dataset.url;
    Store.service = Service;
    Store.service.url = url;
    Store.tabs = new Tabs();
    Store.sidebar = new Sidebar(url);
    Store.editor = new Editor();
    Store.buttons = new FileButtons();
    // Store.toggler = new ViewToggler();
    Store.binaryViewer = new BinaryViewer();
    Helper.getContent();
  }
}
