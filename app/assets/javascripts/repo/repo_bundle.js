/* global monaco */
import Sidebar from './repo_sidebar'
import Editor from './repo_editor'
import Service from './repo_service'
import Store from './repo_store'

export default class RepoBundle {
  constructor() {
    const url = document.getElementById('ide').dataset.url;
    Store.service = Service;
    Store.service.url = url;
    Store.sidebar = new Sidebar(url);
    Store.editor = new Editor();
    Store.sidebar.getContent();
  }
}
