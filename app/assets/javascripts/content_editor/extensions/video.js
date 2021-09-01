import Playable from './playable';

export default Playable.extend({
  name: 'video',
  defaultOptions: {
    ...Playable.options,
    mediaType: 'video',
    extraElementAttrs: { width: '400' },
  },
});
