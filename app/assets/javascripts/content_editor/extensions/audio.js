import Playable from './playable';

export default Playable.extend({
  name: 'audio',
  addOptions() {
    return {
      ...this.parent?.(),
      mediaType: 'audio',
    };
  },
});
