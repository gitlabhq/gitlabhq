import axios from '~/lib/utils/axios_utils';

export default class GroupMemberService {
  constructor(memberContributionsPath) {
    this.memberContributionsPath = memberContributionsPath;
  }

  getContributedMembers() {
    return axios.get(this.memberContributionsPath);
  }
}
