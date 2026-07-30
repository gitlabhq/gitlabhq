import { GlSkeletonLoader, GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiContent from '~/wikis/components/wiki_content.vue';
import * as printTableScale from '~/wikis/utils/print_table_scale';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import waitForPromises from 'helpers/wait_for_promises';
import { handleLocationHash } from '~/lib/utils/common_utils';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/lib/utils/common_utils');

describe('wikis/components/wiki_content', () => {
  const PATH = '/test';
  let wrapper;
  let mock;

  function buildWrapper(propsData = {}) {
    wrapper = shallowMountExtended(WikiContent, {
      provide: {
        contentApi: PATH,
      },
      propsData: { ...propsData },
      stubs: {
        GlSkeletonLoader,
        GlAlert,
      },
    });
  }

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findContent = () => wrapper.findByTestId('wiki-page-content');

  describe('when loading content', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders skeleton loader', () => {
      expect(findGlSkeletonLoader().exists()).toBe(true);
    });

    it('does not render content container or error alert', () => {
      expect(findGlAlert().exists()).toBe(false);
      expect(findContent().exists()).toBe(false);
    });
  });

  describe('when content loads successfully', () => {
    const content = 'content';

    beforeEach(() => {
      mock.onGet(PATH, { params: { render_html: true } }).replyOnce(HTTP_STATUS_OK, { content });
      buildWrapper();
      return waitForPromises();
    });

    it('renders content container', () => {
      expect(findContent().text()).toBe(content);
    });

    it('does not render skeleton loader or error alert', () => {
      expect(findGlAlert().exists()).toBe(false);
      expect(findGlSkeletonLoader().exists()).toBe(false);
    });

    it('calls renderGFM after nextTick', async () => {
      await nextTick();

      expect(renderGFM).toHaveBeenCalled();
    });

    it('handles hash after render', async () => {
      await nextTick();

      expect(handleLocationHash).toHaveBeenCalled();
    });
  });

  describe('when loading content fails', () => {
    beforeEach(() => {
      mock.onGet(PATH).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, '');
      buildWrapper();
      return waitForPromises();
    });

    it('renders error alert', () => {
      expect(findGlAlert().exists()).toBe(true);
    });

    it('does not render skeleton loader or content container', () => {
      expect(findContent().exists()).toBe(false);
      expect(findGlSkeletonLoader().exists()).toBe(false);
    });
  });

  describe('print listeners', () => {
    let addSpy;
    let removeSpy;

    beforeEach(() => {
      addSpy = jest.spyOn(window, 'addEventListener');
      removeSpy = jest.spyOn(window, 'removeEventListener');
    });

    afterEach(() => {
      addSpy.mockRestore();
      removeSpy.mockRestore();
    });

    describe('when mounted', () => {
      beforeEach(() => {
        buildWrapper();
      });

      it('registers beforeprint and afterprint listeners', () => {
        const eventNames = addSpy.mock.calls.map(([name]) => name);
        expect(eventNames).toContain('beforeprint');
        expect(eventNames).toContain('afterprint');
      });
    });

    describe('when destroyed', () => {
      beforeEach(() => {
        buildWrapper();
        wrapper.destroy();
      });

      it('removes the beforeprint and afterprint listeners', () => {
        const eventNames = removeSpy.mock.calls.map(([name]) => name);
        expect(eventNames).toContain('beforeprint');
        expect(eventNames).toContain('afterprint');
      });
    });

    describe('once content has loaded', () => {
      let scaleSpy;
      let resetScrollSpy;
      let restoreScrollSpy;

      beforeEach(() => {
        scaleSpy = jest.spyOn(printTableScale, 'scaleTablesForPrint').mockImplementation();
        restoreScrollSpy = jest.fn();
        resetScrollSpy = jest
          .spyOn(printTableScale, 'resetScrollForPrint')
          .mockReturnValue(restoreScrollSpy);
        mock
          .onGet(PATH, { params: { render_html: true } })
          .replyOnce(HTTP_STATUS_OK, { content: 'x' });
        buildWrapper();
        return waitForPromises();
      });

      describe('on beforeprint', () => {
        beforeEach(() => {
          window.dispatchEvent(new Event('beforeprint'));
        });

        it('scales the rendered content element', () => {
          expect(scaleSpy).toHaveBeenCalledTimes(1);
          expect(scaleSpy).toHaveBeenCalledWith(wrapper.vm.$refs.content);
        });

        it('resets the scroll positions within it', () => {
          expect(resetScrollSpy).toHaveBeenCalledTimes(1);
          expect(resetScrollSpy).toHaveBeenCalledWith(wrapper.vm.$refs.content);
        });

        it('does not restore the scroll positions before printing finishes', () => {
          expect(restoreScrollSpy).not.toHaveBeenCalled();
        });

        describe('and then on afterprint', () => {
          beforeEach(() => {
            window.dispatchEvent(new Event('afterprint'));
          });

          it('restores the scroll positions', () => {
            expect(restoreScrollSpy).toHaveBeenCalledTimes(1);
          });
        });
      });
    });

    describe('while content is still loading', () => {
      let scaleSpy;

      beforeEach(() => {
        scaleSpy = jest.spyOn(printTableScale, 'scaleTablesForPrint');
        // Never resolve, so the component stays in its loading state and the
        // content element is not rendered.
        mock.onGet(PATH, { params: { render_html: true } }).reply(() => new Promise(() => {}));
        buildWrapper();
      });

      describe('on beforeprint', () => {
        it('does not scale, and does not throw', () => {
          expect(() => window.dispatchEvent(new Event('beforeprint'))).not.toThrow();
          expect(scaleSpy).not.toHaveBeenCalled();
        });
      });
    });
  });
});
