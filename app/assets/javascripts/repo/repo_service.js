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

  paramsWithRich(url) {
    // copy the obj so we don't modify perm.
    let params = JSON.parse(JSON.stringify(this.params));
    if(url.substr(url.length-2) === 'md') {
      params.params.viewer = 'rich';
    }
    return params;
  },

  getContent(url) {
    if(url){
      return axios.get(url, this.paramsWithRich(url, params));
    }
    return axios.get(this.url, this.paramsWithRich(this.url, this.params));
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