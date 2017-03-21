export default class SidebarAssigneesStore {
  constructor(currentUser) {
    this.currentUser = currentUser;

    this.users = [{
      avatarUrl: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      name: 'Administrator',
      username: 'username',
    }, {
      avatarUrl: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      name: 'test',
      username: 'username1',
    }, {
      avatarUrl: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      name: 'test',
      username: 'username2',
    }, {
      avatarUrl: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      name: 'test',
      username: 'username3',
    }, {
      avatarUrl: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      name: 'test',
      username: 'username4',
    }, {
      avatarUrl: 'http://www.gravatar.com/avatar/7e65550957227bd38fe2d7fbc6fd2f7b?s=80&d=identicon',
      name: 'test',
      username: 'username5',
    }];
    this.users = [];
  }

  addUser(name, username, avatarUrl) {
    this.users.push({
      avatarUrl,
      name,
      username,
    });
  }

  addCurrentUser() {
    this.users.push(this.currentUser);
  }

  removeUser(username) {
    this.users = this.users.filter((u) => u.username !== username);
  }
}