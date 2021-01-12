import Api from '~/api';
import { registerSchema } from '~/ide/utils';
import { EditorLiteExtension } from './editor_lite_extension_base';
import { EXTENSION_CI_SCHEMA_FILE_NAME_MATCH } from '../constants';

export class CiSchemaExtension extends EditorLiteExtension {
  /**
   * Registers a syntax schema to the editor based on project
   * identifier and commit.
   *
   * The schema is added to the file that is currently edited
   * in the editor.
   *
   * @param {Object} opts
   * @param {String} opts.projectNamespace
   * @param {String} opts.projectPath
   * @param {String?} opts.ref - Current ref. Defaults to master
   */
  registerCiSchema({ projectNamespace, projectPath, ref = 'master' } = {}) {
    const ciSchemaUri = Api.buildUrl(Api.projectFileSchemaPath)
      .replace(':namespace_path', projectNamespace)
      .replace(':project_path', projectPath)
      .replace(':ref', ref)
      .replace(':filename', EXTENSION_CI_SCHEMA_FILE_NAME_MATCH);
    const modelFileName = this.getModel().uri.path.split('/').pop();

    registerSchema({
      uri: ciSchemaUri,
      fileMatch: [modelFileName],
    });
  }
}
