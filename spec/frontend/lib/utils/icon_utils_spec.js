import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import * as iconUtils from '~/lib/utils/icon_utils';

describe('Icon utils', () => {
  describe('getSvgIconPathContent', () => {
    let spriteIcons;

    beforeAll(() => {
      spriteIcons = gon.sprite_icons;
      gon.sprite_icons = 'mockSpriteIconsEndpoint';
    });

    afterAll(() => {
      gon.sprite_icons = spriteIcons;
    });

    let axiosMock;
    let mockEndpoint;
    const mockName = 'mockIconName';
    const mockPath = 'mockPath';
    const getIcon = () => iconUtils.getSvgIconPathContent(mockName);

    beforeEach(() => {
      axiosMock = new MockAdapter(axios);
      mockEndpoint = axiosMock.onGet(gon.sprite_icons);
    });

    afterEach(() => {
      axiosMock.restore();
    });

    it('extracts svg icon path content from sprite icons', () => {
      mockEndpoint.replyOnce(
        200,
        `<svg><symbol id="${mockName}"><path d="${mockPath}"/></symbol></svg>`,
      );

      return getIcon().then(path => {
        expect(path).toBe(mockPath);
      });
    });

    it('returns null if icon path content does not exist', () => {
      mockEndpoint.replyOnce(200, ``);

      return getIcon().then(path => {
        expect(path).toBe(null);
      });
    });

    it('returns null if an http error occurs', () => {
      mockEndpoint.replyOnce(500);

      return getIcon().then(path => {
        expect(path).toBe(null);
      });
    });
  });
});
