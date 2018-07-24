import ListIssue from '~/boards/models/issue';
import IssueProjectEE from './project';

class ListIssueEE extends ListIssue {
  constructor(obj, defaultAvatar) {
    super(obj, defaultAvatar, {
      IssueProject: IssueProjectEE,
    });

    this.isFetching.weight = true;
    this.isLoading.weight = false;
    this.weight = obj.weight;

    if (obj.project) {
      this.project = new IssueProjectEE(obj.project);
    }
  }
}

window.ListIssue = ListIssueEE;

export default ListIssueEE;
