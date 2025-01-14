import { loadViewer, viewers } from '~/repository/components/blob_viewers';
import { OPENAPI_FILE_TYPE, JSON_LANGUAGE } from '~/repository/constants';

describe('Blob Viewers index', () => {
  describe('loadViewer', () => {
    it('loads the openapi viewer', () => {
      const result = loadViewer(OPENAPI_FILE_TYPE, false, false, JSON_LANGUAGE);
      expect(result).toBe(viewers[OPENAPI_FILE_TYPE]);
    });

    it.each`
      type         | isUsingLfs | isTooLarge | expectedViewer
      ${'text'}    | ${false}   | ${true}    | ${viewers.too_large}
      ${'text'}    | ${true}    | ${true}    | ${viewers.too_large}
      ${'unknown'} | ${true}    | ${false}   | ${viewers.lfs}
      ${'unknown'} | ${false}   | ${false}   | ${undefined}
    `(
      'returns $expectedViewer when type=$type, isUsingLfs=$isUsingLfs, isTooLarge=$isTooLarge',
      ({ type, isUsingLfs, isTooLarge, expectedViewer }) => {
        const result = loadViewer(type, isUsingLfs, isTooLarge);
        expect(result).toBe(expectedViewer);
      },
    );

    it.each(['csv', 'image', 'video', 'text', 'pdf', 'audio', 'svg', 'sketch', 'notebook'])(
      'loads %s viewer correctly',
      (type) => {
        const result = loadViewer(type, false, false);
        expect(result).toBe(viewers[type]);
      },
    );
  });
});
