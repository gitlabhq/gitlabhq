import { createWrapper } from '@vue/test-utils';
import Vue from 'vue';
import { injectVueAppBreadcrumbs } from '~/lib/utils/breadcrumbs';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import createMockApollo from 'helpers/mock_apollo_helper';

describe('Breadcrumbs utils', () => {
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
