import BlobViewer from '~/blob/viewer/index';
import initBlob from '~/pages/projects/init_blob';

export default () => {
  new BlobViewer(); // eslint-disable-line no-new
  initBlob();
};
