import { Position } from 'monaco-editor';

export class FileTemplateExtension {
  static get extensionName() {
    return 'FileTemplate';
  }

  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      navigateFileStart: (instance) => {
        instance.setPosition(new Position(1, 1));
      },
    };
  }
}
