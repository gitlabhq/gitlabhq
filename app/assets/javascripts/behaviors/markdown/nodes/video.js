import Playable from './playable';

// Transforms generated HTML back to GFM for Banzai::Filter::VideoLinkFilter
export default class Video extends Playable {
  constructor() {
    super();
    this.mediaType = 'video';
    this.extraElementAttrs = { width: '400' };
  }
}
