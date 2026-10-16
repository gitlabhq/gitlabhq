import Sortable from 'sortablejs';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import LabelManager from '~/labels/label_manager';
import { DRAG_DELAY } from '~/sortable/constants';

describe('LabelManager', () => {
  const findPrioritizedLabels = () => document.querySelector('.js-prioritized-labels');

  const createFixture = ({ sortable = true } = {}) => {
    setHTMLFixture(`
      <ul class="js-prioritized-labels" ${sortable ? 'data-sortable' : ''} data-url="/prioritize">
        <li class="js-label-list-item" data-id="1">Priority Label 1</li>
        <li class="js-label-list-item" data-id="2">Priority Label 2</li>
      </ul>
      <div id="js-priority-labels-empty-state" class="hidden">No priority labels</div>
      <ul class="js-other-labels">
        <li class="js-label-list-item" data-id="3">Other Label 1</li>
      </ul>
    `);
  };

  const createLabelManager = () => new LabelManager();

  afterEach(() => {
    resetHTMLFixture();
    jest.clearAllMocks();
  });

  describe('when prioritized labels are sortable', () => {
    beforeEach(() => {
      createFixture();
      createLabelManager();
    });

    it('makes the prioritized labels list sortable', () => {
      expect(Sortable.create).toHaveBeenCalledTimes(1);
      expect(Sortable.create).toHaveBeenCalledWith(findPrioritizedLabels(), expect.any(Object));
    });

    it('delays dragging on touch devices so that swiping scrolls the page', () => {
      expect(Sortable.create).toHaveBeenCalledWith(
        findPrioritizedLabels(),
        expect.objectContaining({ delay: DRAG_DELAY, delayOnTouchOnly: true }),
      );
    });
  });

  describe('when prioritized labels are not sortable', () => {
    beforeEach(() => {
      createFixture({ sortable: false });
      createLabelManager();
    });

    it('does not make the prioritized labels list sortable', () => {
      expect(Sortable.create).not.toHaveBeenCalled();
    });
  });
});
