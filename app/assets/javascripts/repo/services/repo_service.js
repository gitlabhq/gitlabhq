import axios from 'axios';
import csrf from '../../lib/utils/csrf';
import Store from '../stores/repo_store';
import Api from '../../api';
import Helper from '../helpers/repo_helper';

axios.defaults.headers.common[csrf.headerKey] = csrf.token;

const RepoService = {
  url: '',
  options: {
    params: {
      format: 'json',
    },
  },
  createBranchPath: '/api/:version/projects/:id/repository/branches',
  richExtensionRegExp: /md/,

  getRaw(url) {
    return axios.get(url, {
      // Stop Axios from parsing a JSON file into a JS object
      transformResponse: [res => res],
    });
  },

  buildParams(url = this.url) {
    // shallow clone object without reference
    const params = Object.assign({}, this.options.params);

    if (this.urlIsRichBlob(url)) params.viewer = 'rich';

    return params;
  },

  urlIsRichBlob(url = this.url) {
    const extension = Helper.getFileExtension(url);

    return this.richExtensionRegExp.test(extension);
  },

  getContent(url = this.url) {
    const params = this.buildParams(url);

    return axios.get(url, {
      params,
    });
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

  getBranch() {
    return Api.branchSingle(Store.projectId, Store.currentBranch);
  },

  commitFiles(payload) {
    return Api.commitMultiple(Store.projectId, payload)
      .then(this.commitFlash);
  },

  createBranch(payload) {
    const url = Api.buildUrl(this.createBranchPath)
      .replace(':id', Store.projectId);
    return axios.post(url, payload);
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
