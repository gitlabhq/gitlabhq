import axios from 'axios';

let RepoService = {
  url: '',

  setUrl(url) {
    this.url = url;
  },

  getContent() {
    return axios.get(this.url);
  }
};

export default RepoService;