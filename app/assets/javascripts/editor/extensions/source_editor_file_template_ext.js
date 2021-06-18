import { Position } from 'monaco-editor';
import { SourceEditorExtension } from './source_editor_extension_base';

export class FileTemplateExtension extends SourceEditorExtension {
  navigateFileStart() {
    this.setPosition(new Position(1, 1));
  }
}
