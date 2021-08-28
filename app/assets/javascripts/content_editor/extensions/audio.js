import Playable from './playable';

export default Playable.extend({
  defaultOptions: {
    ...Playable.options,
    mediaType: 'audio',
  },
});
