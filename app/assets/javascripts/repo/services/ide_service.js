import axios from 'axios';

export default {
  url: '',
  getEnpoints() {
    return axios.get(this.url)
      .then((urls) => {
        this.fsUrl = urls.data.fs;
        this.appUrl = urls.data.app;
        this.token = urls.data.token;
      });
  },
  getContent() {
    return this.getEnpoints()
      .then(() => ({
        data: {
          blobs: [],
          trees: [],
          submodules: [],
        },
      }));
  },
  getPreview() {
    return axios.get(this.appUrl, {
      headers: {
        authorization: `Bearer: ${this.token}`,
      },
    });
  },
  blobURLtoParentTree(url) {
    const urlArray = url.split('/');
    urlArray.pop();
    const blobIndex = urlArray.lastIndexOf('blob');

    if (blobIndex > -1) urlArray[blobIndex] = 'tree';

    return urlArray.join('/');
  },
};
