import Vue, { defineComponent, h } from 'vue';
import { createWrapper } from '@vue/test-utils';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { staticBreadcrumbs } from '~/lib/utils/breadcrumbs_state';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import createMockApollo from 'helpers/mock_apollo_helper';

describe('Breadcrumbs utils', () => {
  let wrapper;
  const mockRouter = jest.fn();

  const MockComponent = defineComponent({
    name: 'MockComponent',
    props: {
      allStaticBreadcrumbs: {
        type: Array,
        required: true,
      },
      staticBreadcrumbs: {
        type: Array,
        required: true,
      },
    },
    render: () =>
      h('span', {
        'data-testid': 'mock-component',
        attrs: {
          'data-testid': 'mock-component',
        },
      }),
  });

  const mockApolloProvider = createMockApollo();

  const findMockComponent = () => wrapper.findComponent(MockComponent);

  beforeEach(() => {
    staticBreadcrumbs.items = [
      { text: 'First', href: '/first' },
      { text: 'Last', href: '/last' },
    ];
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('injectVueAppBreadcrumbs', () => {
    describe('when inject target id is not present', () => {
      const emptyBreadcrumbsHTML = `<nav></nav>`;

      beforeEach(() => {
        setHTMLFixture(emptyBreadcrumbsHTML);
      });

      it('returns early and stops trying to inject', () => {
        expect(injectVueAppBreadcrumbs(mockRouter, MockComponent)).toBe(false);
      });
    });

    describe('when inject target id is present', () => {
      const breadcrumbsHTML = `
          <div id="js-vue-page-breadcrumbs-wrapper">
            <nav id="js-vue-page-breadcrumbs" class="gl-breadcrumbs"></nav>
            <div id="js-injected-page-breadcrumbs"></div>
          </div>
        `;

      beforeEach(() => {
        setHTMLFixture(breadcrumbsHTML);
        staticBreadcrumbs.items = [
          { text: 'First', href: '/first' },
          { text: 'Last', href: '/last' },
        ];
      });

      it('mounts given component at the inject target id', () => {
        wrapper = createWrapper(
          injectVueAppBreadcrumbs(mockRouter, MockComponent, mockApolloProvider),
        );

        expect(wrapper.exists()).toBe(true);
        expect(document.querySelectorAll('[data-testid="mock-component"]')).toHaveLength(1);
      });
    });

    describe('staticBreadcrumbs', () => {
      beforeEach(() => {
        const breadcrumbsHTML = `
            <div id="js-vue-page-breadcrumbs-wrapper">
              <nav id="js-vue-page-breadcrumbs" class="gl-breadcrumbs"></nav>
              <div id="js-injected-page-breadcrumbs"></div>
            </div>
          `;
        setHTMLFixture(breadcrumbsHTML);

        wrapper = createWrapper(
          injectVueAppBreadcrumbs(mockRouter, MockComponent, mockApolloProvider),
        );
      });

      it('removes the last item from staticBreadcrumbs and passes it to the component', () => {
        expect(findMockComponent().props('staticBreadcrumbs')).toEqual([
          { text: 'First', href: '/first' },
        ]);
      });

      it('passes all breadrumbs it to the component', () => {
        expect(findMockComponent().props('allStaticBreadcrumbs')).toEqual(staticBreadcrumbs.items);
      });
    });

    describe('when pageBreadcrumbsInTopBar feature flag is enabled', () => {
      const topbarBreadcrumbsHTML = `
          <header class="super-topbar js-super-topbar">
            <div id="js-super-topbar-breadcrumbs-slot"></div>
          </header>
        `;

      beforeEach(() => {
        window.gon = { features: { pageBreadcrumbsInTopBar: true } };
      });

      afterEach(() => {
        staticBreadcrumbs.hasInjectedBreadcrumbs = false;
      });

      describe('when the topbar slot is not present', () => {
        it('returns false', () => {
          expect(injectVueAppBreadcrumbs(mockRouter, MockComponent)).toBe(false);
        });
      });

      describe('when the topbar slot is present', () => {
        beforeEach(() => {
          setHTMLFixture(topbarBreadcrumbsHTML);
        });

        it('sets staticBreadcrumbs.hasInjectedBreadcrumbs to true', () => {
          injectVueAppBreadcrumbs(mockRouter, MockComponent, mockApolloProvider);

          expect(staticBreadcrumbs.hasInjectedBreadcrumbs).toBe(true);
        });

        it('mounts the component at the topbar slot', async () => {
          const app = injectVueAppBreadcrumbs(mockRouter, MockComponent, mockApolloProvider);
          const slot = document.querySelector('#js-super-topbar-breadcrumbs-slot');

          expect(app.$el).toBeInstanceOf(HTMLElement);

          await Vue.nextTick();

          expect(slot.querySelector('[data-testid="mock-component"]')).not.toBeNull();
        });
      });
    });
  });
});
