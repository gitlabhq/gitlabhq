import { createWrapper } from '@vue/test-utils';
import Vue from 'vue';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { staticBreadcrumbs } from '~/lib/utils/breadcrumbs_state';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import createMockApollo from 'helpers/mock_apollo_helper';

describe('Breadcrumbs utils', () => {
  const mockRouter = jest.fn();

  const MockComponent = Vue.component('MockComponent', {
    props: {
      staticBreadcrumbs: {
        type: Array,
        required: true,
      },
    },
    render: (createElement) =>
      createElement('span', {
        attrs: {
          'data-testid': 'mock-component',
        },
      }),
  });

  const mockApolloProvider = createMockApollo();

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
        const wrapper = createWrapper(
          injectVueAppBreadcrumbs(mockRouter, MockComponent, mockApolloProvider),
        );
        expect(wrapper.exists()).toBe(true);
        expect(
          document.querySelectorAll('#js-vue-page-breadcrumbs + [data-testid="mock-component"]'),
        ).toHaveLength(1);
      });
    });

    it('removes the last item from staticBreadcrumbs and passes it to the component', () => {
      const breadcrumbsHTML = `
            <div id="js-vue-page-breadcrumbs-wrapper">
              <nav id="js-vue-page-breadcrumbs" class="gl-breadcrumbs"></nav>
              <div id="js-injected-page-breadcrumbs"></div>
            </div>
          `;
      setHTMLFixture(breadcrumbsHTML);
      staticBreadcrumbs.items = [
        { text: 'First', href: '/first' },
        { text: 'Last', href: '/last' },
      ];
      const wrapper = createWrapper(
        injectVueAppBreadcrumbs(mockRouter, MockComponent, mockApolloProvider),
      );

      const component = wrapper.findComponent(MockComponent);
      expect(component.props('staticBreadcrumbs')).toEqual([{ text: 'First', href: '/first' }]);
    });
  });
});
