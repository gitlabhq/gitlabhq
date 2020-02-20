import Playable from './playable';

// Transforms generated HTML back to GFM for Banzai::Filter::AudioLinkFilter
export default class Audio extends Playable {
  constructor() {
    super();
    this.mediaType = 'audio';
  }
}
