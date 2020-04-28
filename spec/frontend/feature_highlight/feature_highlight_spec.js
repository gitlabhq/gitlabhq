import $ from 'jquery';
import MockAdapter from 'axios-mock-adapter';
import * as featureHighlight from '~/feature_highlight/feature_highlight';
import * as popover from '~/shared/popover';
import axios from '~/lib/utils/axios_utils';

jest.mock('~/shared/popover');

describe('feature highlight', () => {
  beforeEach(() => {
    setFixtures(`
      <div>
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" data-dismiss-endpoint="/test" disabled>
          Trigger
        </div>
      </div>
      <div class="feature-highlight-popover-content">
        Content
        <div class="dismiss-feature-highlight">
          Dismiss
        </div>
      </div>
    `);
  });

  describe('setupFeatureHighlightPopover', () => {
    let mock;
    const selector = '.js-feature-highlight[data-highlight=test]';

    beforeEach(() => {
      mock = new MockAdapter(axios);
      mock.onGet('/test').reply(200);
      jest.spyOn(window, 'addEventListener').mockImplementation(() => {});
      featureHighlight.setupFeatureHighlightPopover('test', 0);
    });

    afterEach(() => {
      mock.restore();
    });

    it('setup popover content', () => {
      const $popoverContent = $('.feature-highlight-popover-content');
      const outerHTML = $popoverContent.prop('outerHTML');

      expect($(selector).data('content')).toEqual(outerHTML);
    });

    it('setup mouseenter', () => {
      $(selector).trigger('mouseenter');

      expect(popover.mouseenter).toHaveBeenCalledWith(expect.any(Object));
    });

    it('setup debounced mouseleave', () => {
      $(selector).trigger('mouseleave');

      expect(popover.debouncedMouseleave).toHaveBeenCalled();
    });

    it('setup show.bs.popover', () => {
      $(selector).trigger('show.bs.popover');

      expect(window.addEventListener).toHaveBeenCalledWith('scroll', expect.any(Function), {
        once: true,
      });
    });

    it('removes disabled attribute', () => {
      expect($('.js-feature-highlight').is(':disabled')).toEqual(false);
    });
  });

  describe('findHighestPriorityFeature', () => {
    beforeEach(() => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-high-priority" data-highlight-priority="20" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-low-priority" data-highlight-priority="0" disabled></div>
      `);
    });

    it('should pick the highest priority feature highlight', () => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-high-priority" data-highlight-priority="20" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-low-priority" data-highlight-priority="0" disabled></div>
      `);

      expect($('.js-feature-highlight').length).toBeGreaterThan(1);
      expect(featureHighlight.findHighestPriorityFeature()).toEqual('test-high-priority');
    });

    it('should work when no priority is set', () => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test" disabled></div>
      `);

      expect(featureHighlight.findHighestPriorityFeature()).toEqual('test');
    });

    it('should pick the highest priority feature highlight when some have no priority set', () => {
      setFixtures(`
        <div class="js-feature-highlight" data-highlight="test-no-priority1" disabled></div>
        <div class="js-feature-highlight" data-highlight="test" data-highlight-priority="10" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-no-priority2" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-high-priority" data-highlight-priority="20" disabled></div>
        <div class="js-feature-highlight" data-highlight="test-low-priority" data-highlight-priority="0" disabled></div>
      `);

      expect($('.js-feature-highlight').length).toBeGreaterThan(1);
      expect(featureHighlight.findHighestPriorityFeature()).toEqual('test-high-priority');
    });
  });

  describe('highlightFeatures', () => {
    it('calls setupFeatureHighlightPopover', () => {
      expect(featureHighlight.highlightFeatures()).toEqual('test');
    });
  });
});
