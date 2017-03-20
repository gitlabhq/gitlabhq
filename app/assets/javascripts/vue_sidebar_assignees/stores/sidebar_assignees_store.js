export default class SidebarAssigneesStore {
  constructor() {
    this.users = [{
      avatar_url: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      url: '/user4',
      name: 'test',
      username: 'username',
    }, {
      avatar_url: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      url: '/user4',
      name: 'test',
      username: 'username1',
    }, {
      avatar_url: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      url: '/user4',
      name: 'test',
      username: 'username2',
    }, {
      avatar_url: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      url: '/user4',
      name: 'test',
      username: 'username3',
    }, {
      avatar_url: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      url: '/user4',
      name: 'test',
      username: 'username4',
    }, {
      avatar_url: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      url: '/user4',
      name: 'test',
      username: 'username5',
    }];
    this.users = [];
  }

  addUser() {
    this.users.push({
      avatar_url: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      url: '/user4',
      name: 'test',
      username: 'username6',
    });
  }

  removeUser(username) {
    this.users = this.users.filter((u) => u.username !== username);
  }
}