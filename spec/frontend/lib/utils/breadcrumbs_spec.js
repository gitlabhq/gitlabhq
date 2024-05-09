import { createWrapper } from '@vue/test-utils';
import Vue from 'vue';
import { injectVueAppBreadcrumbs, staticBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import createMockApollo from 'helpers/mock_apollo_helper';

describe('Breadcrumbs utils', () => {
  const mockRouter = jest.fn();

  const MockComponent = Vue.component('MockComponent', {
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
    describe('when vue_page_breadcrumbs feature flag is enabled', () => {
      beforeEach(() => {
        window.gon = { features: { vuePageBreadcrumbs: true } };
      });

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

        it('nulls text and href of the last static breadcrumb item', () => {
          injectVueAppBreadcrumbs(mockRouter, MockComponent);
          expect(staticBreadcrumbs.items[0].text).toBe('First');
          expect(staticBreadcrumbs.items[0].href).toBe('/first');
          expect(staticBreadcrumbs.items[1].text).toBe('');
          expect(staticBreadcrumbs.items[1].href).toBe('');
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
    });

    describe('when vue_page_breadcrumbs feature flag is disabled', () => {
      const breadcrumbsHTML = `
        <nav>
          <ul class="js-breadcrumbs-list">
            <li>
              <a href="/group-name" data-testid="existing-crumb">Group name</a>
            </li>
            <li>
              <a href="/group-name/project-name/-/subpage" data-testid="last-crumb">Subpage</a>
            </li>
          </ul>
        </nav>
      `;

      const emptyBreadcrumbsHTML = `
        <nav>
          <ul class="js-breadcrumbs-list" data-testid="breadcumbs-list">
          </ul>
        </nav>
      `;

      beforeEach(() => {
        window.gon = { features: { vuePageBreadcrumbs: false } };
      });

      describe('without any breadcrumbs', () => {
        beforeEach(() => {
          setHTMLFixture(emptyBreadcrumbsHTML);
        });

        it('returns early and stops trying to inject', () => {
          expect(injectVueAppBreadcrumbs(mockRouter, MockComponent)).toBe(false);
        });
      });

      describe('with breadcrumbs', () => {
        beforeEach(() => {
          setHTMLFixture(breadcrumbsHTML);
        });

        describe.each`
          testLabel    | apolloProvider
          ${'set'}     | ${mockApolloProvider}
          ${'not set'} | ${null}
        `('given the apollo provider is $testLabel', ({ apolloProvider }) => {
          beforeEach(() => {
            createWrapper(injectVueAppBreadcrumbs(mockRouter, MockComponent, apolloProvider));
          });

          it('returns a new breadcrumbs component replacing the inject HTML', () => {
            // Using `querySelectorAll` because we're not testing a full Vue app.
            // We are testing a partial Vue app added into the pages HTML.
            expect(document.querySelectorAll('[data-testid="existing-crumb"]')).toHaveLength(1);
            expect(document.querySelectorAll('[data-testid="last-crumb"]')).toHaveLength(0);
            expect(document.querySelectorAll('[data-testid="mock-component"]')).toHaveLength(1);
          });
        });
      });
    });
  });
});
