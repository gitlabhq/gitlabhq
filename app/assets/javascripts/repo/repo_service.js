import axios from 'axios';

let RepoService = {
  url: '',

  setUrl(url) {
    this.url = url;
  },

  getContent(url) {
    if(url){
      return axios.get(url);  
    }
    return axios.get(this.url);
  }
};

export default RepoService;