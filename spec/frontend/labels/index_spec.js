import { initLabels } from '~/labels/index';
import eventHub, { EVENT_ARCHIVE_LABEL_SUCCESS } from '~/labels/event_hub';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('Labels index', () => {
  beforeEach(() => {
    setHTMLFixture(`
      <div class="labels-container">
        <div class="prioritized-labels">
          <ul class="js-prioritized-labels">
            <li class="js-label-list-item" data-id="1">Priority Label 1</li>
            <li class="js-label-list-item" data-id="2">Priority Label 2</li>
          </ul>
          <div id="js-priority-labels-empty-state" class="hidden">No priority labels</div>
        </div>
        <div class="other-labels">
          <ul class="js-other-labels">
            <li class="js-label-list-item" data-id="3">Other Label 1</li>
            <li class="js-label-list-item" data-id="4">Other Label 2</li>
            <li class="js-label-list-item" data-id="5">Other Label 3</li>
          </ul>
      </div>
    `);

    window.gon = { features: { labelsArchive: true } };

    jest.spyOn(eventHub, '$on');
  });

  afterEach(() => {
    resetHTMLFixture();
    jest.restoreAllMocks();
  });

  describe('initLabels', () => {
    it('registers EVENT_ARCHIVE_LABEL_SUCCESS event listener when labelsArchive feature is enabled', () => {
      initLabels();

      expect(eventHub.$on).toHaveBeenCalledWith(EVENT_ARCHIVE_LABEL_SUCCESS, expect.any(Function));
    });

    it('does not register EVENT_ARCHIVE_LABEL_SUCCESS event listener when labelsArchive feature is disabled', () => {
      window.gon.features.labelsArchive = false;

      initLabels();

      expect(eventHub.$on).not.toHaveBeenCalledWith(
        EVENT_ARCHIVE_LABEL_SUCCESS,
        expect.any(Function),
      );
    });

    describe('removeLabelSuccessCallback', () => {
      beforeEach(() => {
        initLabels();
      });

      it('hides a prioritized archived label element', () => {
        const labelElement = document.querySelector('[data-id="1"]');
        expect(labelElement.classList.contains('!gl-hidden')).toBe(false);

        eventHub.$emit(EVENT_ARCHIVE_LABEL_SUCCESS, '1');

        expect(labelElement.classList.contains('!gl-hidden')).toBe(true);
      });

      it('hides an other archived label element', () => {
        const labelElement = document.querySelector('[data-id="4"]');
        expect(labelElement.classList.contains('!gl-hidden')).toBe(false);

        eventHub.$emit(EVENT_ARCHIVE_LABEL_SUCCESS, '4');

        expect(labelElement.classList.contains('!gl-hidden')).toBe(true);
      });
    });
  });
});
