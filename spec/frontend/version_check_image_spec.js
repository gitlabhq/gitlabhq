import $ from 'jquery';
import VersionCheckImage from '~/version_check_image';
import ClassSpecHelper from './helpers/class_spec_helper';

describe('VersionCheckImage', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  describe('bindErrorEvent', () => {
    ClassSpecHelper.itShouldBeAStaticMethod(VersionCheckImage, 'bindErrorEvent');

    beforeEach(() => {
      testContext.imageElement = $('<div></div>');
    });

    it('registers an error event', () => {
      jest.spyOn($.prototype, 'on').mockImplementation(() => {});
      // eslint-disable-next-line func-names
      jest.spyOn($.prototype, 'off').mockImplementation(function() {
        return this;
      });

      VersionCheckImage.bindErrorEvent(testContext.imageElement);

      expect($.prototype.off).toHaveBeenCalledWith('error');
      expect($.prototype.on).toHaveBeenCalledWith('error', expect.any(Function));
    });

    it('hides the imageElement on error', () => {
      jest.spyOn($.prototype, 'hide').mockImplementation(() => {});

      VersionCheckImage.bindErrorEvent(testContext.imageElement);

      testContext.imageElement.trigger('error');

      expect($.prototype.hide).toHaveBeenCalled();
    });
  });
});
