import FilterableList from '~/filterable_list';

export default class ProjectsFilterableList extends FilterableList {
  getFilterEndpoint() {
    return this.getPagePath().replace('/projects?', '/projects.json?');
  }
}
