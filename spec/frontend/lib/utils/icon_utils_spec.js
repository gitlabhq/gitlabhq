import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { clearSvgIconPathContentCache, getSvgIconPathContent } from '~/lib/utils/icon_utils';

describe('Icon utils', () => {
  describe('getSvgIconPathContent', () => {
    let spriteIcons;
    let axiosMock;
    const mockName = 'mockIconName';
    const mockPath = 'mockPath';
    const mockIcons = `<svg><symbol id="${mockName}"><path d="${mockPath}"/></symbol></svg>`;

    beforeAll(() => {
      spriteIcons = gon.sprite_icons;
      gon.sprite_icons = 'mockSpriteIconsEndpoint';
    });

    afterAll(() => {
      gon.sprite_icons = spriteIcons;
    });

    beforeEach(() => {
      axiosMock = new MockAdapter(axios);
    });

    afterEach(() => {
      axiosMock.restore();
      clearSvgIconPathContentCache();
    });

    describe('when the icons can be loaded', () => {
      beforeEach(() => {
        axiosMock.onGet(gon.sprite_icons).reply(HTTP_STATUS_OK, mockIcons);
      });

      it('extracts svg icon path content from sprite icons', () => {
        return getSvgIconPathContent(mockName).then((path) => {
          expect(path).toBe(mockPath);
        });
      });

      it('returns null if icon path content does not exist', () => {
        return getSvgIconPathContent('missing-icon').then((path) => {
          expect(path).toBe(null);
        });
      });
    });

    describe('when the icons cannot be loaded on the first 2 tries', () => {
      beforeEach(() => {
        axiosMock
          .onGet(gon.sprite_icons)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR)
          .onGet(gon.sprite_icons)
          .replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR)
          .onGet(gon.sprite_icons)
          .reply(HTTP_STATUS_OK, mockIcons);
      });

      it('returns null', () => {
        return getSvgIconPathContent(mockName).then((path) => {
          expect(path).toBe(null);
        });
      });

      it('extracts svg icon path content, after 2 attempts', () => {
        return getSvgIconPathContent(mockName)
          .then((path1) => {
            expect(path1).toBe(null);
            return getSvgIconPathContent(mockName);
          })
          .then((path2) => {
            expect(path2).toBe(null);
            return getSvgIconPathContent(mockName);
          })
          .then((path3) => {
            expect(path3).toBe(mockPath);
          });
      });
    });
  });
});
