import { staticBreadcrumbs } from '~/lib/utils/breadcrumbs_state';
import {
  initPageBreadcrumbs,
  destroySuperSidebarBreadcrumbs,
} from '~/super_sidebar/super_sidebar_breadcrumbs';

jest.mock('@gitlab/ui', () => ({
  GlBreadcrumb: { name: 'GlBreadcrumb', render: (h) => h('nav') },
}));

const mockBreadcrumbsJson = JSON.stringify([
  { text: 'Group', href: '/group' },
  { text: 'Project', href: '/group/project' },
]);

describe('Super sidebar breadcrumbs', () => {
  let el;
  let wrapperEl;
  let panelEl;

  const createEl = () => {
    wrapperEl = document.createElement('div');
    wrapperEl.id = 'js-vue-page-breadcrumbs-wrapper';
    panelEl = document.createElement('div');
    panelEl.class = 'js-static-panel';
    el = document.createElement('div');
    el.id = 'js-vue-page-breadcrumbs';
    el.dataset.breadcrumbsJson = mockBreadcrumbsJson;
    wrapperEl.appendChild(el);
    panelEl.appendChild(wrapperEl);
    document.body.appendChild(panelEl);
  };

  afterEach(() => {
    destroySuperSidebarBreadcrumbs();
    el?.remove();
    wrapperEl?.remove();
    staticBreadcrumbs.items = [];
  });

  describe('initPageBreadcrumbs', () => {
    it('returns false when element does not exist', () => {
      expect(initPageBreadcrumbs()).toBe(false);
    });

    describe('when element exists', () => {
      beforeEach(() => {
        createEl();
      });

      it('populates staticBreadcrumbs.items from the element dataset', () => {
        initPageBreadcrumbs();

        expect(staticBreadcrumbs.items).toEqual(JSON.parse(mockBreadcrumbsJson));
      });

      describe('when pageBreadcrumbsInTopBar feature flag is disabled', () => {
        beforeEach(() => {
          window.gon = { features: { pageBreadcrumbsInTopBar: false } };
        });

        it('mounts the Vue breadcrumbs app', () => {
          const app = initPageBreadcrumbs();

          expect(app.$el).toBeInstanceOf(HTMLElement);
        });
      });

      describe('when pageBreadcrumbsInTopBar feature flag is enabled', () => {
        beforeEach(() => {
          window.gon = { features: { pageBreadcrumbsInTopBar: true } };
        });

        it('does not mount the Vue breadcrumbs app', () => {
          const result = initPageBreadcrumbs();

          expect(result).toBe(false);
        });

        it('still populates staticBreadcrumbs.items', () => {
          initPageBreadcrumbs();

          expect(staticBreadcrumbs.items).toEqual(JSON.parse(mockBreadcrumbsJson));
        });

        it('removes the HAML breadcrumb wrapper from the main panel', () => {
          initPageBreadcrumbs();

          expect(
            document.querySelector('.js-static-panel #js-vue-page-breadcrumbs-wrapper'),
          ).toBeNull();
        });
      });
    });
  });

  describe('destroySuperSidebarBreadcrumbs', () => {
    it('does not throw when no app has been mounted', () => {
      expect(() => destroySuperSidebarBreadcrumbs()).not.toThrow();
    });

    it('destroys a mounted app and removes its DOM element', () => {
      createEl();
      window.gon = { features: {} };
      initPageBreadcrumbs();

      expect(wrapperEl.childNodes.length).toBeGreaterThan(0);

      destroySuperSidebarBreadcrumbs();

      expect(wrapperEl.childNodes).toHaveLength(0);
    });
  });
});
