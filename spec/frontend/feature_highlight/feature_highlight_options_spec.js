import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import domContentLoaded from '~/feature_highlight/feature_highlight_options';

describe('feature highlight options', () => {
  describe('domContentLoaded', () => {
    it.each`
      breakPoint | shouldCall
      ${'xs'}    | ${false}
      ${'sm'}    | ${false}
      ${'md'}    | ${false}
      ${'lg'}    | ${false}
      ${'xl'}    | ${true}
    `(
      'when breakpoint is $breakPoint should call highlightFeatures is $shouldCall',
      ({ breakPoint, shouldCall }) => {
        jest.spyOn(bp, 'getBreakpointSize').mockReturnValue(breakPoint);

        expect(domContentLoaded()).toBe(shouldCall);
      },
    );
  });
});
