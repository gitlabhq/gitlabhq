import MockAdapter from 'axios-mock-adapter';
import { registerSchema } from '~/ide/utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { TEST_HOST } from 'helpers/test_constants';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import {
  getSecurityPolicyListUrl,
  getSecurityPolicySchemaUrl,
  getSinglePolicySchema,
  SecurityPolicySchemaExtension,
} from '~/editor/extensions/source_editor_security_policy_schema_ext';
import SourceEditor from '~/editor/source_editor';

jest.mock('~/ide/utils');

const mockNamespacePath = 'mock-namespace';

const mockSchema = {
  $id: 1,
  title: 'mockSchema',
  description: 'mockDescriptions',
  type: 'Object',
  properties: {
    scan_execution_policy: { items: { properties: { foo: 'bar' } } },
    scan_result_policy: { items: { properties: { fizz: 'buzz' } } },
  },
};

const createMockOutput = (policyType) => ({
  $id: mockSchema.$id,
  title: mockSchema.title,
  description: mockSchema.description,
  type: mockSchema.type,
  properties: {
    type: {
      type: 'string',
      description: 'Specifies the type of policy to be enforced.',
      enum: policyType,
    },
    ...mockSchema.properties[policyType].items.properties,
  },
});

describe('getSecurityPolicyListUrl', () => {
  it.each`
    input                                                     | output
    ${{ namespacePath: '' }}                                  | ${`${TEST_HOST}/groups/-/security/policies`}
    ${{ namespacePath: 'test', namespaceType: 'group' }}      | ${`${TEST_HOST}/groups/test/-/security/policies`}
    ${{ namespacePath: '', namespaceType: 'project' }}        | ${`${TEST_HOST}/-/security/policies`}
    ${{ namespacePath: 'test', namespaceType: 'project' }}    | ${`${TEST_HOST}/test/-/security/policies`}
    ${{ namespacePath: undefined, namespaceType: 'project' }} | ${`${TEST_HOST}/-/security/policies`}
    ${{ namespacePath: undefined, namespaceType: 'group' }}   | ${`${TEST_HOST}/groups/-/security/policies`}
    ${{ namespacePath: null, namespaceType: 'project' }}      | ${`${TEST_HOST}/-/security/policies`}
    ${{ namespacePath: null, namespaceType: 'group' }}        | ${`${TEST_HOST}/groups/-/security/policies`}
  `('returns `$output` when passed `$input`', ({ input, output }) => {
    expect(getSecurityPolicyListUrl(input)).toBe(output);
  });
});

describe('getSecurityPolicySchemaUrl', () => {
  it.each`
    namespacePath | namespaceType | output
    ${'test'}     | ${'project'}  | ${`${TEST_HOST}/test/-/security/policies/schema`}
    ${'test'}     | ${'group'}    | ${`${TEST_HOST}/groups/test/-/security/policies/schema`}
  `(
    'returns $output when passed $namespacePath and $namespaceType',
    ({ namespacePath, namespaceType, output }) => {
      expect(getSecurityPolicySchemaUrl({ namespacePath, namespaceType })).toBe(output);
    },
  );
});

describe('getSinglePolicySchema', () => {
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  it.each`
    policyType
    ${'scan_execution_policy'}
    ${'scan_result_policy'}
  `('returns the appropriate schema on request success for $policyType', async ({ policyType }) => {
    mock.onGet().reply(HTTP_STATUS_OK, mockSchema);

    await expect(
      getSinglePolicySchema({
        namespacePath: mockNamespacePath,
        namespaceType: 'project',
        policyType,
      }),
    ).resolves.toStrictEqual(createMockOutput(policyType));
  });

  it('returns an empty schema on request failure', async () => {
    await expect(
      getSinglePolicySchema({
        namespacePath: mockNamespacePath,
        namespaceType: 'project',
        policyType: 'scan_execution_policy',
      }),
    ).resolves.toStrictEqual({});
  });

  it('returns an empty schema on non-existing policy type', async () => {
    await expect(
      getSinglePolicySchema({
        namespacePath: mockNamespacePath,
        namespaceType: 'project',
        policyType: 'non_existent_policy',
      }),
    ).resolves.toStrictEqual({});
  });
});

describe('SecurityPolicySchemaExtension', () => {
  let mock;
  let editor;
  let instance;
  let editorEl;

  const createMockEditor = ({ blobPath = '.gitlab/security-policies/policy.yml' } = {}) => {
    setHTMLFixture('<div id="editor"></div>');
    editorEl = document.getElementById('editor');
    editor = new SourceEditor();
    instance = editor.createInstance({ el: editorEl, blobPath, blobContent: '' });
    instance.use({ definition: SecurityPolicySchemaExtension });
  };

  beforeEach(() => {
    createMockEditor();
    mock = new MockAdapter(axios);
    mock.onGet().reply(HTTP_STATUS_OK, mockSchema);
  });

  afterEach(() => {
    instance.dispose();
    editorEl.remove();
    resetHTMLFixture();
    mock.restore();
  });

  describe('registerSecurityPolicyEditorSchema', () => {
    describe('register validations options with monaco for yaml language', () => {
      it('registers the schema', async () => {
        const policyType = 'scan_execution_policy';
        await instance.registerSecurityPolicyEditorSchema({
          namespacePath: mockNamespacePath,
          namespaceType: 'project',
          policyType,
        });

        expect(registerSchema).toHaveBeenCalledTimes(1);
        expect(registerSchema).toHaveBeenCalledWith({
          uri: `${TEST_HOST}/${mockNamespacePath}/-/security/policies/schema`,
          schema: createMockOutput(policyType),
          fileMatch: ['policy.yml'],
        });
      });
    });
  });

  describe('registerSecurityPolicySchema', () => {
    describe('register validations options with monaco for yaml language', () => {
      it('registers the schema', async () => {
        await instance.registerSecurityPolicySchema(mockNamespacePath);
        expect(registerSchema).toHaveBeenCalledTimes(1);
        expect(registerSchema).toHaveBeenCalledWith({
          uri: `${TEST_HOST}/${mockNamespacePath}/-/security/policies/schema`,
          fileMatch: ['policy.yml'],
        });
      });
    });
  });
});
