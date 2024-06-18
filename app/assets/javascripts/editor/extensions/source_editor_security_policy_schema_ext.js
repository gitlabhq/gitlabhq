import { registerSchema } from '~/ide/utils';
import axios from '~/lib/utils/axios_utils';
import { getBaseURL, joinPaths } from '~/lib/utils/url_utility';

export const getSecurityPolicyListUrl = ({ namespacePath, namespaceType = 'group' }) => {
  const isGroup = namespaceType === 'group';
  return joinPaths(
    getBaseURL(),
    isGroup ? 'groups' : '',
    namespacePath,
    '-',
    'security',
    'policies',
  );
};

export const getSecurityPolicySchemaUrl = ({ namespacePath, namespaceType }) => {
  const policyListUrl = getSecurityPolicyListUrl({ namespacePath, namespaceType });
  return joinPaths(policyListUrl, 'schema');
};

export const getSinglePolicySchema = async ({ namespacePath, namespaceType, policyType }) => {
  try {
    const { data: schemaForMultiplePolicies } = await axios.get(
      getSecurityPolicySchemaUrl({ namespacePath, namespaceType }),
    );
    const properties =
      schemaForMultiplePolicies.properties[policyType]?.items?.properties ||
      schemaForMultiplePolicies.$defs[policyType]?.items?.properties ||
      {};
    return {
      title: schemaForMultiplePolicies.title,
      description: schemaForMultiplePolicies.description,
      type: schemaForMultiplePolicies.type,
      properties: {
        type: {
          type: 'string',
          // eslint-disable-next-line @gitlab/require-i18n-strings
          description: 'Specifies the type of policy to be enforced.',
          enum: policyType,
        },
        ...properties,
      },
    };
  } catch {
    return {};
  }
};

export class SecurityPolicySchemaExtension {
  static get extensionName() {
    return 'SecurityPolicySchema';
  }
  // eslint-disable-next-line class-methods-use-this
  provides() {
    return {
      registerSecurityPolicyEditorSchema: async (instance, options) => {
        const { namespacePath, namespaceType, policyType } = options;
        const singlePolicySchema = await getSinglePolicySchema({
          namespacePath,
          namespaceType,
          policyType,
        });
        const modelFileName = instance.getModel().uri.path.split('/').pop();

        registerSchema({
          uri: getSecurityPolicySchemaUrl({ namespacePath, namespaceType }),
          schema: singlePolicySchema,
          fileMatch: [modelFileName],
        });
      },

      registerSecurityPolicySchema: (instance, projectPath) => {
        const uri = getSecurityPolicySchemaUrl({
          namespacePath: projectPath,
          namespaceType: 'project',
        });
        const modelFileName = instance.getModel().uri.path.split('/').pop();

        registerSchema({
          uri,
          fileMatch: [modelFileName],
        });
      },
    };
  }
}
