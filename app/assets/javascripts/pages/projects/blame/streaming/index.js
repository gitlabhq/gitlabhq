import initBlob from '~/pages/projects/init_blob';
import { renderBlamePageStreams } from '~/blame/streaming';

renderBlamePageStreams(window.blamePageStream);
initBlob();
