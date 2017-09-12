export default class ProjectsStore {
  constructor() {
    this.state = {};
    this.state.frequentProjects = [];
    this.state.searchedProjects = [];
  }

  setFrequentProjects(rawProjects) {
    this.state.frequentProjects = rawProjects;
  }

  getFrequentProjects() {
    return this.state.frequentProjects;
  }

  setSearchedProjects(rawProjects) {
    this.state.searchedProjects = rawProjects.map(rawProject => ({
      id: rawProject.id,
      name: rawProject.name,
      namespace: rawProject.name_with_namespace,
      webUrl: rawProject.web_url,
      avatarUrl: rawProject.avatar_url,
    }));
  }

  getSearchedProjects() {
    return this.state.searchedProjects;
  }

  clearSearchedProjects() {
    this.state.searchedProjects = [];
  }
}
