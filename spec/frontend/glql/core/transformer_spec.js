import { glql } from '@gitlab/query-language-rust';
import { transform } from '~/glql/core/transformer';

jest.mock('@gitlab/query-language-rust', () => ({
  glql: {
    transform: jest.fn(),
  },
}));

describe('transform', () => {
  const mockData = { project: { workItems: { nodes: [] } } };
  const mockFields = 'title, state';
  const mockMode = 'analytics';

  afterEach(() => {
    jest.resetAllMocks();
  });

  it('passes fields and mode to glql.transform', async () => {
    glql.transform.mockResolvedValue({ success: true, data: { nodes: [] } });

    await transform(mockData, { fields: mockFields, mode: mockMode });

    expect(glql.transform).toHaveBeenCalledWith(mockData, {
      fields: mockFields,
      mode: mockMode,
    });
  });

  it('returns result.data on success', async () => {
    const expectedData = { nodes: [{ title: 'Issue 1' }], pageInfo: { hasNextPage: false } };
    glql.transform.mockResolvedValue({ success: true, data: expectedData });

    const result = await transform(mockData, { fields: mockFields, mode: mockMode });

    expect(result).toEqual(expectedData);
  });

  it('throws an error when result is not successful', async () => {
    glql.transform.mockResolvedValue({ success: false, error: 'Transform failed' });

    await expect(transform(mockData, { fields: mockFields, mode: mockMode })).rejects.toThrow(
      'Transform failed',
    );
  });
});
