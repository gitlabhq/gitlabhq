/* global Flash */
import axios from 'axios';
import Store from '../stores/repo_store';
import Api from '../../api';

const RepoService = {
  url: '',
  options: {
    params: {
      format: 'json',
    },
  },
  getRaw(url) {
    return axios.get(url, {
      // Stop Axios from parsing a JSON file into a JS object
      transformResponse: [res => res],
    });
  },
  getContent(url = this.url, withParams = true) {
    const params = Object.assign({}, this.options.params);

    return withParams ? axios.get(url, { params }) : axios.get(url);
  },
  getBase64Content(url = this.url) {
    const request = axios.get(url, {
      responseType: 'arraybuffer',
    });

    return request.then(response => this.bufferToBase64(response.data));
  },
  bufferToBase64(data) {
    return new Buffer(data, 'binary').toString('base64');
  },
  blobURLtoParentTree(url) {
    const urlArray = url.split('/');
    urlArray.pop();
    const blobIndex = urlArray.lastIndexOf('blob');

    if (blobIndex > -1) urlArray[blobIndex] = 'tree';

    return urlArray.join('/');
  },
  commitFiles(payload) {
    return Api.commitMultiple(Store.projectId, payload)
      .then(this.commitFlash);
  },
  commitFlash(data) {
    if (data.short_id && data.stats) {
      window.Flash(`Your changes have been committed. Commit ${data.short_id} with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`, 'notice');
    } else {
      window.Flash(data.message);
    }
  },
};

export default RepoService;
