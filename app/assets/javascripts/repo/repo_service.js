import axios from 'axios';

let RepoService = {
  url: '',
  params: {
    params: {
      format: 'json'
    }
  },

  setUrl(url) {
    this.url = url;
  },

  getContent(url) {
    if(url){
      return axios.get(url, this.params);  
    }
    return axios.get(this.url, this.params);
  },

  getBase64Content(url) {
    return axios
      .get(url, {
        responseType: 'arraybuffer'
      })
      .then(response => new Buffer(response.data, 'binary').toString('base64'))
  }
};

export default RepoService;