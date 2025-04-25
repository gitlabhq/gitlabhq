import { updateQueryHistory, paramsFromQuery } from '~/projects/pipelines/charts/url_utils';
import { updateHistory } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  updateHistory: jest.fn(),
}));

const defaults = {
  source: null,
  branch: 'main',
  dateRange: '7d',
};

describe('dashboard utils', () => {
  const examples = [
    { input: {}, query: '' },
    { input: defaults, query: '' },
    { input: { source: 'PUSH' }, query: '?source=PUSH' },
    { input: { branch: 'feature-branch' }, query: '?branch=feature-branch' },
    { input: { dateRange: '180d' }, query: '?time=180d' },
    {
      input: { dateRange: '180d', branch: 'feature-branch', source: 'PUSH' },
      query: '?branch=feature-branch&source=PUSH&time=180d',
    },
  ];

  describe('updateQueryHistory', () => {
    it.each(examples)('updates history to "http://test.host/$query"', ({ input, query }) => {
      updateQueryHistory(input, defaults);

      expect(updateHistory).toHaveBeenLastCalledWith({ url: `http://test.host/${query}` });
    });
  });

  describe('paramsFromQuery', () => {
    it.each(examples)('updates history to "http://test.host/$query"', ({ query, input }) => {
      expect(paramsFromQuery(query, defaults)).toEqual({ ...defaults, ...input });
    });
  });
});
