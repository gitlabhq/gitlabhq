export default class IssueProject {
  constructor(obj) {
    this.id = obj.id;
    this.path = obj.path;
    this.fullPath = obj.path_with_namespace;
  }
}
