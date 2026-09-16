import $ from 'jquery';
import BranchGraph from '~/network/branch_graph';
import Raphael from '~/network/raphael';

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

    it('truncates messages longer than 100 characters', () => {
      const longMessage = 'a'.repeat(101);
      graph.drawDot(0, 0, makeCommit(longMessage));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, `${'a'.repeat(100)}…`);
    });

    it('does not truncate messages of exactly 100 characters', () => {
      const exactMessage = 'a'.repeat(100);
      graph.drawDot(0, 0, makeCommit(exactMessage));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, exactMessage);
    });

    it('does not truncate a message under 100 characters', () => {
      const message = 'a'.repeat(99);

      graph.drawDot(0, 0, makeCommit(message));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, message);
    });

    it('uses only the first line of a multi-line message', () => {
      graph.drawDot(0, 0, makeCommit('first line\nsecond line'));

      expect(mockR.text).toHaveBeenCalledWith(expect.any(Number), 0, 'first line');
    });

    it('exposes the untruncated subject as the title for hover', () => {
      const longMessage = 'a'.repeat(101);
      graph.drawDot(0, 0, makeCommit(longMessage));

      expect(mockText.attr).toHaveBeenCalledWith(expect.objectContaining({ title: longMessage }));
    });
  });

  describe('prepareData', () => {
    const CONTAINER_WIDTH = 600;
    let graph;

    beforeEach(() => {
      jest.spyOn(BranchGraph.prototype, 'load').mockImplementation();
      Raphael.mockReturnValue({ set: jest.fn().mockReturnValue({ toFront: jest.fn() }) });
      jest.spyOn($.fn, 'height').mockReturnValue(500);
      jest.spyOn($.fn, 'width').mockReturnValue(CONTAINER_WIDTH);

      graph = new BranchGraph($(document.createElement('div')), {});
    });

    const prepareCommits = (messages) =>
      graph.prepareData(
        [[1, 'Jan', 2026]],
        messages.map((message, index) => ({
          message,
          id: `sha${index}`,
          space: 0,
          time: index,
          parents: [],
          author: { icon: 'https://example.com/avatar.png' },
        })),
      );

    it('widens the canvas so the longest subject fits', () => {
      prepareCommits(['a'.repeat(100)]);

      // offsetX 150 + 0 lanes + 40 offset + (100 chars * 9) + 20 padding
      expect(Raphael).toHaveBeenCalledWith(expect.anything(), 1110, expect.any(Number));
    });

    it('keeps room for the hover tooltip when every subject is short', () => {
      graph.offsetX = 900; // force the content-driven branch past the 600px container

      prepareCommits(['short']);

      // offsetX 900 + 0 lanes + 325 tooltip, since 40 + 5 chars * 9 + 20 is narrower
      expect(Raphael).toHaveBeenCalledWith(expect.anything(), 1225, expect.any(Number));
    });

    it('does not shrink the canvas below the container width', () => {
      prepareCommits(['short']);

      expect(Raphael).toHaveBeenCalledWith(expect.anything(), CONTAINER_WIDTH, expect.any(Number));
    });
  });
});
