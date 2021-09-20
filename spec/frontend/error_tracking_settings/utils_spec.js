import { transformFrontendSettings } from '~/error_tracking_settings/utils';
import { sampleFrontendSettings, transformedSettings } from './mock';

describe('error tracking settings utils', () => {
  describe('data transform functions', () => {
    it('should transform settings successfully for the backend', () => {
      expect(transformFrontendSettings(sampleFrontendSettings)).toEqual(transformedSettings);
    });

    it('should transform empty values in the settings object to null', () => {
      const emptyFrontendSettingsObject = {
        apiHost: '',
        enabled: false,
        integrated: false,
        token: '',
        selectedProject: null,
      };
      const transformedEmptySettingsObject = {
        api_host: null,
        enabled: false,
        integrated: false,
        token: null,
        project: null,
      };

      expect(transformFrontendSettings(emptyFrontendSettingsObject)).toEqual(
        transformedEmptySettingsObject,
      );
    });
  });
});
