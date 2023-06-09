import { GlDrawer, GlAlert, GlSkeletonLoader } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MarkdownDrawer, { cache } from '~/vue_shared/components/markdown_drawer/markdown_drawer.vue';
import { getRenderedMarkdown } from '~/vue_shared/components/markdown_drawer/utils/fetch';
import { contentTop } from '~/lib/utils/common_utils';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';

jest.mock('~/vue_shared/components/markdown_drawer/utils/fetch', () => ({
  getRenderedMarkdown: jest.fn().mockReturnValue({
    title: 'test title test',
    body: `<div id="content-body">
          <div class="documentation md gl-mt-3">
            test body
          </div>
      </div>`,
  }),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  contentTop: jest.fn(),
}));

describe('MarkdownDrawer', () => {
  let wrapper;
  const defaultProps = {
    documentPath: 'user/search/global_search/advanced_search_syntax.json',
  };

  const createComponent = (props) => {
    wrapper = shallowMountExtended(MarkdownDrawer, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    Object.keys(cache).forEach((key) => delete cache[key]);
  });

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findSkeleton = () => wrapper.findComponent(GlSkeletonLoader);
  const findDrawerTitle = () => wrapper.findComponent('[data-testid="title-element"]');
  const findDrawerBody = () => wrapper.findComponent({ ref: 'content-element' });

  describe('component', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders correctly', () => {
      expect(findDrawer().exists()).toBe(true);
      expect(findDrawerTitle().text()).toBe('test title test');
      expect(findDrawerBody().text()).toBe('test body');
    });

    it(`has proper z-index set for the drawer component`, () => {
      expect(findDrawer().attributes('zindex')).toBe(DRAWER_Z_INDEX.toString());
    });
  });

  describe.each`
    hasNavbar | navbarHeight
    ${false}  | ${0}
    ${true}   | ${100}
  `('computes offsetTop', ({ hasNavbar, navbarHeight }) => {
    beforeEach(() => {
      global.document.querySelector = jest.fn(() =>
        hasNavbar
          ? {
              dataset: {
                page: 'test',
              },
            }
          : undefined,
      );
      contentTop.mockReturnValue(navbarHeight);
      createComponent();
    });

    afterEach(() => {
      contentTop.mockClear();
    });

    it(`computes offsetTop ${hasNavbar ? 'with' : 'without'} .navbar-gitlab`, async () => {
      wrapper.vm.getDrawerTop();
      await Vue.nextTick();

      expect(findDrawer().attributes('headerheight')).toBe(`${navbarHeight}px`);
    });
  });

  describe('watcher', () => {
    let renderGLFMSpy;
    let fetchMarkdownSpy;

    beforeEach(async () => {
      renderGLFMSpy = jest.spyOn(MarkdownDrawer.methods, 'renderGLFM');
      fetchMarkdownSpy = jest.spyOn(MarkdownDrawer.methods, 'fetchMarkdown');
      global.document.querySelector = jest.fn(() => ({
        dataset: {
          page: 'test',
        },
      }));
      contentTop.mockReturnValue(100);
      createComponent();
      await nextTick();
    });

    afterEach(() => {
      renderGLFMSpy.mockClear();
      fetchMarkdownSpy.mockClear();
    });

    it('for documentPath triggers fetch', async () => {
      expect(fetchMarkdownSpy).toHaveBeenCalledTimes(1);

      await wrapper.setProps({ documentPath: '/test/me' });
      await nextTick();

      expect(fetchMarkdownSpy).toHaveBeenCalledTimes(2);
    });

    it('triggers renderGLFM in openDrawer', async () => {
      wrapper.vm.fetchMarkdown();
      wrapper.vm.openDrawer();
      await nextTick();
      expect(renderGLFMSpy).toHaveBeenCalled();
    });

    it('triggers height calculation in openDrawer', async () => {
      expect(findDrawer().attributes('headerheight')).toBe(`${0}px`);
      wrapper.vm.fetchMarkdown();
      wrapper.vm.openDrawer();
      await nextTick();
      expect(findDrawer().attributes('headerheight')).toBe(`${100}px`);
    });

    it('triggers height calculation in toggleDrawer', async () => {
      expect(findDrawer().attributes('headerheight')).toBe(`${0}px`);
      wrapper.vm.fetchMarkdown();
      wrapper.vm.toggleDrawer();
      await nextTick();
      expect(findDrawer().attributes('headerheight')).toBe(`${100}px`);
    });
  });

  describe('Markdown fetching', () => {
    let renderGLFMSpy;

    beforeEach(async () => {
      renderGLFMSpy = jest.spyOn(MarkdownDrawer.methods, 'renderGLFM');
      createComponent();
      await nextTick();
    });

    afterEach(() => {
      renderGLFMSpy.mockClear();
    });

    it('fetches the Markdown and caches it', () => {
      expect(getRenderedMarkdown).toHaveBeenCalledTimes(1);
      expect(Object.keys(cache)).toHaveLength(1);
    });

    it('when the document changes, fetches it and caches it as well', async () => {
      expect(getRenderedMarkdown).toHaveBeenCalledTimes(1);
      expect(Object.keys(cache)).toHaveLength(1);

      await wrapper.setProps({ documentPath: '/test/me2' });
      await nextTick();

      expect(getRenderedMarkdown).toHaveBeenCalledTimes(2);
      expect(Object.keys(cache)).toHaveLength(2);
    });

    it('when re-using an already fetched document, gets it from the cache', async () => {
      await wrapper.setProps({ documentPath: '/test/me2' });
      await nextTick();

      expect(getRenderedMarkdown).toHaveBeenCalledTimes(2);
      expect(Object.keys(cache)).toHaveLength(2);

      await wrapper.setProps({ documentPath: defaultProps.documentPath });
      await nextTick();

      expect(getRenderedMarkdown).toHaveBeenCalledTimes(2);
      expect(Object.keys(cache)).toHaveLength(2);
    });
  });

  describe('Markdown fetching returns error', () => {
    beforeEach(async () => {
      getRenderedMarkdown.mockReturnValue({
        hasFetchError: true,
      });

      createComponent();
      await nextTick();
    });
    afterEach(() => {
      getRenderedMarkdown.mockClear();
    });
    it('shows an alert', () => {
      expect(findAlert().exists()).toBe(true);
    });
  });

  describe('While Markdown is fetching', () => {
    beforeEach(() => {
      getRenderedMarkdown.mockReturnValue(new Promise(() => {}));

      createComponent();
    });

    afterEach(() => {
      getRenderedMarkdown.mockClear();
    });

    it('shows skeleton', () => {
      expect(findSkeleton().exists()).toBe(true);
    });
  });
});
