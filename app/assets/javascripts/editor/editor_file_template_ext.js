import { Position } from 'monaco-editor';

export default {
  navigateFileStart() {
    this.setPosition(new Position(1, 1));
  },
};
