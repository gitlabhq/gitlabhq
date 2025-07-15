import Ajax from '~/filtered_search/droplab/plugins/ajax';
import AjaxCache from '~/lib/utils/ajax_cache';

describe('Ajax', () => {
  describe('preprocessing', () => {
    const config = {};

    describe('is not configured', () => {
      it('passes the data through', () => {
        const data = ['data'];

        expect(Ajax.preprocessing(config, data)).toEqual(data);
      });
    });

    describe('is configured', () => {
      const processedArray = ['processed'];

      beforeEach(() => {
        config.preprocessing = () => processedArray;
        jest.spyOn(config, 'preprocessing').mockImplementation(() => processedArray);
      });

      it('calls preprocessing', () => {
        Ajax.preprocessing(config, []);

        expect(config.preprocessing.mock.calls).toHaveLength(1);
      });

      it('overrides AjaxCache', () => {
        jest.spyOn(AjaxCache, 'override').mockImplementation((endpoint, results) => {
          expect(results).toEqual(processedArray);
        });

        Ajax.preprocessing(config, []);

        expect(AjaxCache.override.mock.calls).toHaveLength(1);
      });
    });
  });
});
