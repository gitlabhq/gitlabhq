import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';
import { getSelector, dismiss, inserted } from '~/feature_highlight/feature_highlight_helper';
import { togglePopover } from '~/shared/popover';

describe('feature highlight helper', () => {
  describe('getSelector', () => {
    it('returns js-feature-highlight selector', () => {
      const highlightId = 'highlightId';

      expect(getSelector(highlightId)).toEqual(
        `.js-feature-highlight[data-highlight=${highlightId}]`,
      );
    });
  });

  describe('dismiss', () => {
    const context = {
      hide: () => {},
      attr: () => '/-/callouts/dismiss',
    };

    beforeEach(() => {
      jest.spyOn(axios, 'post').mockResolvedValue();
      jest.spyOn(togglePopover, 'call').mockImplementation(() => {});
      jest.spyOn(context, 'hide').mockImplementation(() => {});
      dismiss.call(context);
    });

    it('calls persistent dismissal endpoint', () => {
      expect(axios.post).toHaveBeenCalledWith(
        '/-/callouts/dismiss',
        expect.objectContaining({ feature_name: undefined }),
      );
    });

    it('calls hide popover', () => {
      expect(togglePopover.call).toHaveBeenCalledWith(context, false);
    });

    it('calls hide', () => {
      expect(context.hide).toHaveBeenCalled();
    });
  });

  describe('inserted', () => {
    it('registers click event callback', done => {
      const context = {
        getAttribute: () => 'popoverId',
        dataset: {
          highlight: 'some-feature',
        },
      };

      jest.spyOn($.fn, 'on').mockImplementation(event => {
        expect(event).toEqual('click');
        done();
      });
      inserted.call(context);
    });
  });
});
