import playable from './playable';

// Transforms generated HTML back to GFM for Banzai::Filter::AudioLinkFilter
export default () => playable({ mediaType: 'audio' });
