import initBlob from '~/pages/projects/init_blob';
import redirectToCorrectPage from '~/blame/blame_redirect';
import { renderBlamePageStreams } from '~/blame/streaming';

if (new URLSearchParams(window.location.search).get('streaming')) {
  renderBlamePageStreams(window.blamePageStream);
} else {
  redirectToCorrectPage();
}
initBlob();
