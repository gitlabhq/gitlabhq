import Playable from './playable';

export default Playable.extend({
  name: 'video',
  addOptions() {
    return {
      ...this.parent?.(),
      mediaType: 'video',
    };
  },
});
