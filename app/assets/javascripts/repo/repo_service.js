import axios from 'axios';

let RepoService = {
  url: '',

  setUrl(url) {
    this.url = url;
  },

  getTree() {
    return axios.get(this.url);
  }
};

export default RepoService;