import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import CommitListItemDescription from '~/projects/commits/components/commit_list_item_description.vue';
import commitDescriptionQuery from '~/projects/commits/graphql/queries/commit_details.query.graphql';
import { mockCommit, mockCommitDescriptionQueryResponse } from './mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');

describe('CommitListItemDescription', () => {
  let wrapper;

  const defaultProvide = {
    projectFullPath: 'gitlab-org/gitlab',
  };

  const descriptionQueryHandler = jest.fn().mockResolvedValue(mockCommitDescriptionQueryResponse());

  const createComponent = (handler = descriptionQueryHandler) => {
    wrapper = shallowMountExtended(CommitListItemDescription, {
      apolloProvider: createMockApollo([[commitDescriptionQuery, handler]]),
      provide: defaultProvide,
      propsData: {
        commitSha: mockCommit.sha,
      },
    });
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDescription = () => wrapper.find('pre');

  describe('when loading', () => {
    beforeEach(() => createComponent());

    it('renders loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not render description', () => {
      expect(findDescription().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('hides loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders description in pre element', () => {
      expect(findDescription().exists()).toBe(true);
    });

    it('calls query with correct variables', () => {
      expect(descriptionQueryHandler).toHaveBeenCalledWith({
        projectPath: defaultProvide.projectFullPath,
        ref: mockCommit.sha,
      });
    });
  });

  describe('newline character handling', () => {
    const NEWLINE_CHAR = '&#x000A;';
    const descriptionText = 'Description after newline';

    const createComponentWithRawDirective = (handler) => {
      wrapper = shallowMountExtended(CommitListItemDescription, {
        apolloProvider: createMockApollo([[commitDescriptionQuery, handler]]),
        provide: defaultProvide,
        propsData: { commitSha: mockCommit.sha },
        directives: {
          // Stub directive to render the raw value without HTML entity decoding,
          // allowing us to verify the newline stripping logic via the DOM.
          SafeHtml(el, binding) {
            el.textContent = binding.value;
          },
        },
      });
    };

    it.each`
      scenario                     | input                                  | expected
      ${'with leading newline'}    | ${`${NEWLINE_CHAR}${descriptionText}`} | ${descriptionText}
      ${'without leading newline'} | ${descriptionText}                     | ${descriptionText}
    `('renders description correctly $scenario', async ({ input, expected }) => {
      const handler = jest.fn().mockResolvedValue(mockCommitDescriptionQueryResponse(input));
      createComponentWithRawDirective(handler);
      await waitForPromises();

      expect(findDescription().text()).toBe(expected);
    });
  });

  describe('when query fails', () => {
    it('shows error message from error object when available', async () => {
      createComponent(jest.fn().mockRejectedValue(new Error('Custom error message')));
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Custom error message',
          captureError: true,
        }),
      );
    });

    it('shows default error message when error has no message', async () => {
      createComponent(jest.fn().mockRejectedValue(new Error()));
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Something went wrong while loading the commit description. Please try again.',
          captureError: true,
        }),
      );
    });
  });
});
