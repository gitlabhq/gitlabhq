import { createWrapper } from '@vue/test-utils';
import { defineComponent, h } from 'vue';
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
  });
});
