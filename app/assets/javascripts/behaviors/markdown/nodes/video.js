import playable from './playable';

// Transforms generated HTML back to GFM for Banzai::Filter::VideoLinkFilter
export default () => playable({ mediaType: 'video', extraElementAttrs: { width: '400' } });
