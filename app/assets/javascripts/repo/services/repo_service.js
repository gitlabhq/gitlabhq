/* global Flash */
import axios from 'axios';
import Store from '../stores/repo_store';
import Api from '../../api';
import Helper from '../helpers/repo_helper';

const RepoService = {
  url: '',
  options: {
    params: {
      format: 'json',
    },
  },
  richExtensionRegExp: /md/,

  checkCurrentBranchIsCommitable() {
    const url = Store.service.refsUrl;
    return axios.get(url, { params: {
      ref: Store.currentBranch,
      search: Store.currentBranch,
    } });
  },

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

  commitFiles(payload, cb) {
    Api.commitMultiple(Store.projectId, payload, (data) => {
      Flash(`Your changes have been committed. Commit ${data.short_id} with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`, 'notice');
      cb();
    });
  },
};

export default RepoService;
