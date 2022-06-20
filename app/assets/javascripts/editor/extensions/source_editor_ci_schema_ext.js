import ciSchemaPath from '~/editor/schema/ci.json';
import { registerSchema } from '~/ide/utils';

export class CiSchemaExtension {
  static get extensionName() {
    return 'CiSchema';
  }
  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      registerCiSchema: (instance) => {
        // In order for workers loaded from `data://` as the
        // ones loaded by monaco editor, we use absolute URLs
        // to fetch schema files, hence the `gon.gitlab_url`
        // reference. This prevents error:
        //   "Failed to execute 'fetch' on 'WorkerGlobalScope'"
        const absoluteSchemaUrl = new URL(ciSchemaPath, gon.gitlab_url).href;
        const modelFileName = instance.getModel().uri.path.split('/').pop();

        registerSchema(
          {
            uri: absoluteSchemaUrl,
            fileMatch: [modelFileName],
          },
          // eslint-disable-next-line @gitlab/require-i18n-strings
          { customTags: ['!reference sequence'] },
        );
      },
    };
  }
}
