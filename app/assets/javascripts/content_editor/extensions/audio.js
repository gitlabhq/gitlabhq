import Playable from './playable';

export default Playable.extend({
  name: 'audio',
  defaultOptions: {
    ...Playable.options,
    mediaType: 'audio',
  },
});
