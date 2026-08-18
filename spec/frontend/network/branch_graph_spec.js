import BranchGraph from '~/network/branch_graph';

jest.mock('~/network/raphael');
jest.mock('~/lib/utils/axios_utils');

describe('BranchGraph', () => {
  describe('drawDot', () => {
    let graph;
    let mockR;
    let mockText;

    beforeEach(() => {
      jest.spyOn(BranchGraph.prototype, 'load').mockImplementation();
      mockText = { attr: jest.fn() };
      mockR = {
        circle: jest.fn().mockReturnValue({ attr: jest.fn() }),
        image: jest.fn(),
        rect: jest.fn().mockReturnValue({ attr: jest.fn() }),
        text: jest.fn().mockReturnValue(mockText),
      };
      graph = new BranchGraph(null, {});
      graph.r = mockR;
      graph.colors = ['#ff0000'];
      graph.offsetX = 150;
      graph.unitSpace = 10;
      graph.mspace = 5;
    });

    const makeCommit = (message) => ({
      message,
      space: 0,
      author: { icon: 'https://example.com/avatar.png' },
    });

    it('truncates messages longer than 30 characters', () => {
      const longMessage = 'a'.repeat(31);
      graph.drawDot(0, 0, makeCommit(longMessage));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, `${'a'.repeat(30)}…`);
    });

    it('does not truncate messages of exactly 30 characters', () => {
      const exactMessage = 'a'.repeat(30);
      graph.drawDot(0, 0, makeCommit(exactMessage));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, exactMessage);
    });

    it('does not truncate messages shorter than 30 characters', () => {
      graph.drawDot(0, 0, makeCommit('short commit'));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, 'short commit');
    });

    it('uses only the first line of a multi-line message', () => {
      graph.drawDot(0, 0, makeCommit('first line\nsecond line'));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, 'first line');
    });
  });
});
