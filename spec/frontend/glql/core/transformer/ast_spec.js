import { transformAstToDisplayFields } from '~/glql/core/transformer/ast';
import * as ast from '~/glql/core/parser/ast';

describe('transformAstToDisplayFields', () => {
  it('transforms a single field name', () => {
    const input = ast.fieldName('title');
    const result = transformAstToDisplayFields(input);
    expect(result).toEqual({
      key: 'title',
      label: 'Title',
      name: 'title',
    });
  });

  it('transforms multiple field names', () => {
    const input = ast.collection(
      ast.fieldName('title'),
      ast.fieldName('description'),
      ast.fieldName('createdAt'),
    );
    const result = transformAstToDisplayFields(input);
    expect(result).toEqual([
      { key: 'title', label: 'Title', name: 'title' },
      { key: 'descriptionHtml', label: 'Description', name: 'descriptionHtml' },
      { key: 'createdAt', label: 'Created at', name: 'createdAt' },
    ]);
  });

  it('transforms multiple field names with aliases', () => {
    const input = ast.collection(
      ast.fieldName('assignee'),
      ast.fieldName('due'),
      ast.fieldName('closed'),
      ast.fieldName('health'),
    );
    const result = transformAstToDisplayFields(input);
    expect(result).toEqual([
      { key: 'assignees', label: 'Assignee', name: 'assignees' },
      { key: 'dueDate', label: 'Due', name: 'dueDate' },
      { key: 'closedAt', label: 'Closed', name: 'closedAt' },
      { key: 'healthStatus', label: 'Health', name: 'healthStatus' },
    ]);
  });

  it('transforms a function call with multiple arguments', () => {
    const input = ast.functionCall(
      'labels',
      ast.collection(ast.string('bug'), ast.string('feature'), ast.string('test')),
    );
    const result = transformAstToDisplayFields(input);
    expect(result).toMatchObject({
      key: expect.stringMatching(/^labels_bug_feature_test_/),
      label: 'Labels: Bug, Feature, Test',
      name: expect.any(String),
      transform: expect.any(Function),
    });
  });

  it('transforms a mix of field names and function calls', () => {
    const input = ast.collection(
      ast.fieldName('title'),
      ast.functionCall('labels', ast.collection(ast.string('bug'))),
      ast.fieldName('description'),
    );
    const result = transformAstToDisplayFields(input);
    expect(result).toEqual([
      { key: 'title', label: 'Title', name: 'title' },
      {
        key: expect.stringMatching(/^labels_bug_/),
        label: 'Label: Bug',
        name: expect.any(String),
        transform: expect.any(Function),
      },
      { key: 'descriptionHtml', label: 'Description', name: 'descriptionHtml' },
    ]);
  });

  it('throws an error for unknown AST node types', () => {
    const input = { type: 'unknown', value: 'test' };
    expect(() => transformAstToDisplayFields(input)).toThrow('Unknown value type: unknown');
  });
});
