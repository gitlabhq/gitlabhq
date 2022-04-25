let id = 1;

// Code taken from: https://gist.github.com/6174/6062387
const getRandomString = () =>
  Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15);

const getRandomUrl = () => `https://${getRandomString()}.com/${getRandomString()}`;

export default {
  createNumberRandomUsers(numberUsers) {
    const users = [];
    for (let i = 0; i < numberUsers; i += 1) {
      users.push({
        avatar_url: getRandomUrl(),
        id: id + 1,
        name: getRandomString(),
        username: getRandomString(),
        web_url: getRandomUrl(),
      });

      id += 1;
    }
    return users;
  },

  createRandomUser() {
    return this.createNumberRandomUsers(1)[0];
  },
};
