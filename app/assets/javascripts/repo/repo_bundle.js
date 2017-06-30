import Tabs from './repo_tabs'
import Sidebar from './repo_sidebar'
import Editor from './repo_editor'
import Service from './repo_service'
import Store from './repo_store'
import Helper from './repo_helper'

export default class RepoBundle {
  constructor() {
    console.log(document.getElementById('ide'))
    const url = document.getElementById('ide').dataset.url;
    Store.service = Service;
    Store.service.url = url;
    Store.tabs = new Tabs();
    Store.sidebar = new Sidebar(url);
    Store.editor = new Editor();
    Helper.getContent();
  }
}
