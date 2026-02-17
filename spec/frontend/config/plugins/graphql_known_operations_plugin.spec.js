import GraphqlKnownOperationsPlugin from '../../../../config/plugins/graphql_known_operations_plugin';

describe('GraphqlKnownOperationsPlugin - Directive Extraction', () => {
  let plugin;
  let mockCompiler;
  let mockCompilation;

  beforeEach(() => {
    plugin = new GraphqlKnownOperationsPlugin({ filename: 'test-operations.yml' });

    mockCompilation = {
      hooks: {
        succeedModule: {
          tap: jest.fn(),
        },
      },
      getAsset: jest.fn(() => null),
      updateAsset: jest.fn(),
      emitAsset: jest.fn(),
    };

    mockCompiler = {
      hooks: {
        emit: {
          tap: jest.fn(),
        },
        compilation: {
          tap: jest.fn(),
        },
      },
    };
  });

  const setupPlugin = () => {
    plugin.apply(mockCompiler);
    const compilationCallback = mockCompiler.hooks.compilation.tap.mock.calls[0][1];
    compilationCallback(mockCompilation);
    const emitCallback = mockCompiler.hooks.emit.tap.mock.calls[0][1];
    return {
      succeedModuleCallback: mockCompilation.hooks.succeedModule.tap.mock.calls[0][1],
      emitCallback,
    };
  };

  const createModule = (comments, operationName, operationType = 'query') => {
    const doc = {
      kind: 'Document',
      definitions: [
        {
          kind: 'OperationDefinition',
          operation: operationType,
          name: {
            kind: 'Name',
            value: operationName,
          },
          variableDefinitions: [],
          directives: [],
          selectionSet: {
            kind: 'SelectionSet',
            selections: [],
          },
        },
      ],
      loc: {
        start: 0,
        end: 10,
      },
    };

    const commentsWithTerminator = comments + (comments ? '\\' : '');
    const escapedComments = JSON.stringify(commentsWithTerminator);
    const graphqlSource = `var __comments = ${escapedComments};
var doc = ${JSON.stringify(doc)};
module.exports = doc;
`;

    return {
      resource: '/path/to/query.graphql',
      originalSource: () => ({
        source: () => Buffer.from(graphqlSource),
      }),
    };
  };

  const getEmittedYaml = () => {
    const emitAssetCall = mockCompilation.emitAsset.mock.calls[0];
    if (!emitAssetCall) return null;
    const source = emitAssetCall[1];
    return source.source().toString();
  };

  describe('extracting @feature_category directive', () => {
    it('extracts feature_category from GraphQL comment', () => {
      const comments = '# @feature_category: code_review';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetMergeRequest');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetMergeRequest:');
      expect(yaml).toContain('feature_category: code_review');
    });

    it('extracts feature_category with underscores', () => {
      const comments = '# @feature_category: source_code_management';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetRepository');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetRepository:');
      expect(yaml).toContain('feature_category: source_code_management');
    });

    it('handles missing feature_category directive', () => {
      const comments = '';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetProject');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetProject:');
      expect(yaml).toContain('feature_category: null');
    });
  });

  describe('extracting @urgency directive', () => {
    it('extracts urgency: high', () => {
      const comments = '# @urgency: high';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'UpdateIssue', 'mutation');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('UpdateIssue:');
      expect(yaml).toContain('urgency: high');
    });

    it('extracts urgency: low', () => {
      const comments = '# @urgency: low';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetStats');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetStats:');
      expect(yaml).toContain('urgency: low');
    });

    it('handles missing urgency directive (defaults to "default")', () => {
      const comments = '';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetIssue');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetIssue:');
      expect(yaml).toContain('urgency: default');
    });
  });

  describe('extracting both @feature_category and @urgency directives', () => {
    it('extracts both directives when present', () => {
      const comments = `# @feature_category: code_review
# @urgency: high`;
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetMergeRequest');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetMergeRequest:');
      expect(yaml).toContain('feature_category: code_review');
      expect(yaml).toContain('urgency: high');
    });

    it('extracts both directives with extra whitespace', () => {
      const comments = `#   @feature_category:   continuous_integration
#   @urgency:   high`;
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetPipeline');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetPipeline:');
      expect(yaml).toContain('feature_category: continuous_integration');
      expect(yaml).toContain('urgency: high');
    });

    it('extracts directives with other comments present', () => {
      const comments = `# This query fetches merge request data
# @feature_category: code_review
# TODO: Add pagination support
# @urgency: high
# Note: This is used in the MR widget`;
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetMergeRequestDetails');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('GetMergeRequestDetails:');
      expect(yaml).toContain('feature_category: code_review');
      expect(yaml).toContain('urgency: high');
    });
  });

  describe('regex extraction validation', () => {
    it('correctly extracts values with special characters', () => {
      const comments = '# @feature_category: continuous_integration';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetPipeline');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('feature_category: continuous_integration');
    });

    it('stops extraction at newline', () => {
      const comments = `# @feature_category: code_review
# next line should not be included`;
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetMergeRequest');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('feature_category: code_review');
      expect(yaml).not.toContain('next line');
    });

    it('trims whitespace from extracted values', () => {
      const comments = `# @feature_category:    code_review
# @urgency:    low   `;
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetProject');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('feature_category: code_review');
      expect(yaml).toContain('urgency: low');
      expect(yaml).not.toMatch(/code_review\s+\n/);
    });

    it('only extracts the first match per directive', () => {
      const comments = `# @feature_category: code_review
# @feature_category: issues`;
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetMergeRequest');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain('feature_category: code_review');
      expect(yaml).not.toContain('feature_category: issues');
    });

    it('handles colons in directive values', () => {
      const comments = '# @feature_category: code_review:mr_widget';
      const { succeedModuleCallback, emitCallback } = setupPlugin();
      const module = createModule(comments, 'GetMergeRequest');

      succeedModuleCallback(module);
      emitCallback(mockCompilation);

      const yaml = getEmittedYaml();
      expect(yaml).toContain("feature_category: 'code_review:mr_widget'");
    });
  });
});
