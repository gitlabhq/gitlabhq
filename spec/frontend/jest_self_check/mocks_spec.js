import * as textUtils from '~/lib/utils/text_utility';

jest.mock('~/lib/utils/text_utility');

describe('does restore mocks config work?', () => {
  describe('shared spy', () => {
    const spy = jest.fn();

    beforeEach(() => {
      spy();
    });

    it('is only called once', () => {
      expect(spy).toHaveBeenCalledTimes(1);
    });

    it('is only called once B', () => {
      expect(spy).toHaveBeenCalledTimes(1);
    });

    it('is only called once C', () => {
      expect(spy).toHaveBeenCalledTimes(1);
    });
  });

  describe('module mock', () => {
    beforeEach(() => {
      textUtils.humanize('');
    });

    it('is only called once', () => {
      expect(textUtils.humanize).toHaveBeenCalledTimes(1);
    });

    it('is only called once B', () => {
      expect(textUtils.humanize).toHaveBeenCalledTimes(1);
    });

    it('is only called once C', () => {
      expect(textUtils.humanize).toHaveBeenCalledTimes(1);
    });
  });
});
