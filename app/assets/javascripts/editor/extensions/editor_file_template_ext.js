import { Position } from 'monaco-editor';
import { EditorLiteExtension } from './editor_lite_extension_base';

export class FileTemplateExtension extends EditorLiteExtension {
  navigateFileStart() {
    this.setPosition(new Position(1, 1));
  }
}
